# encoding: utf-8

require 'fileutils'
require 'nokogiri'

STEREOTYPY = [
"prehled",
"karta",
"evidence",
"zalozeni",
"zmena",
"smazani",
"urceni",
"sestava",
"formular"
]

BARVA_ODKAZU_UC = '#ff0080'
BARVA_ODKAZU_TRIDA = '#0000ff'

PREFIX = "/XMI/XMI.content/UML:Model/UML:Namespace.ownedElement/UML:Package/UML:Namespace.ownedElement"

class Linker

  def initialize(project_name)
    @project_name = project_name
  end  

  def go(input_xml_file, output_xml_file)
    FileUtils.cp(input_xml_file, output_xml_file)

    File.open(output_xml_file, 'r') {|f| @doc = Nokogiri::XML(f)}
    transformace_notes
    File.open(output_xml_file, 'w') {|f| f.print @doc.to_xml}
  end

  def transformace_notes
    nodes = @doc.xpath(PREFIX + "/UML:Package[@name = '#{@project_name}']/UML:Namespace.ownedElement/UML:Package[@name='Use Case Model' or @name='Class Model' or @name='Business Process Model']//UML:ModelElement.taggedValue//UML:TaggedValue[@tag='documentation' or @tag='description']/@value")
    nodes.each do |node|
      print '.'
      # ztucneni titulku
      node.content = node.content.gsub(/^==([^=.]+)==/) { |m| '<b>' + $1.lstrip.rstrip + '</b>' }  
      node.content = node.content.gsub(/^===([^=.]+)===/) { |m| '<b>' + $1.lstrip.rstrip + '</b>' }  
      # ztucneni v hvezdickach
      node.content = node.content.gsub(/\*([^\*]+)\*/) { |m| '<b>' + $1.lstrip.rstrip + '</b>' }  
      # vyrobeni odkazu
      node.content = node.content.gsub(/\[\[\w+\]\]/) { |m| odkaz(m)}
    end
  end  

  def odkaz(jmeno) 
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    if vnitrek[0..2] == 'uc_'
      odkaz_na_uc(jmeno)
    elsif vnitrek[0..5] == 'ac_bp_'
      odkaz_na_bp(jmeno)
    elsif vnitrek.match('_') 
      if vnitrek[-1,1] == '_'
        odkaz_na_metodu(jmeno)
      else  
        ret = odkaz_na_atribut(jmeno)
        if ret[0..1] == '[['
          ret = odkaz_na_asociaci(jmeno)
        end  
        ret
      end  
    else 
      odkaz_na_class(jmeno)
    end    
  end

  def odkaz_na_uc(jmeno)
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    vysledek = najdi_identifikator_uc(vnitrek)
    if vysledek != nil
      id = vysledek[0]
      text = vysledek[1]
      id.gsub!('EAID_', '').gsub!('_', '-')
      ret = '<a href="$element://{' + id + '}"><font color="' + BARVA_ODKAZU_UC + '"><u>' + text + '</u></font></a>'
    else
      ret = jmeno
    end  
    ret
  end  

  def odkaz_na_bp(jmeno)
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    vysledek = najdi_identifikator_bp(vnitrek)
    if vysledek != nil
      id = vysledek[0]
      text = vysledek[1]
      id.gsub!('EAID_', '').gsub!('_', '-')
      ret = '<a href="$element://{' + id + '}"><font color="' + BARVA_ODKAZU_TRIDA + '"><u>' + text + '</u></font></a>'
    else
      ret = jmeno
    end  
    ret
  end  
  
  def odkaz_na_class(jmeno)
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    vysledek = najdi_identifikator_class(vnitrek)
    if vysledek != nil
      id = vysledek[0]
      text = vysledek[1]
      id.gsub!('EAID_', '').gsub!('_', '-')
      ret = '<a href="$element://{' + id + '}"><font color="' + BARVA_ODKAZU_TRIDA + '"><u>' + text + '</u></font></a>'
    else
      ret = jmeno
    end  
    ret
  end  

  def odkaz_na_atribut(jmeno)
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    vnitrek.match('(.+)_(.+)')
    trida = $1
    atribut = $2
    vysledek = najdi_identifikator_class(trida)
    if vysledek != nil
      id = vysledek[0]
      text = vysledek[1]
      id.gsub!('EAID_', '').gsub!('_', '-')
      ret = '<a href="$element://{' + id + '}"><font color="' + BARVA_ODKAZU_TRIDA + '"><u>' + text + '</u></font></a>'
      vysledek = najdi_identifikator_atribut(trida,atribut)
      if vysledek != nil
        id = vysledek[0]
        text = vysledek[1]
        ret = ret + '.' + '<a href="$feature://' + id + '"><font color="' + BARVA_ODKAZU_TRIDA + '"><u>' + text + '</u></font></a>'
      else
        ret = jmeno
      end
    else
      ret = jmeno
    end  
    ret  
  end  

  def odkaz_na_asociaci(jmeno)
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    vnitrek.match('(.+)_(.+)')
    trida = $1
    atribut = $2
    vysledek = najdi_identifikator_class(trida)
    if vysledek != nil
      id = vysledek[0]
      text = vysledek[1]
      id.gsub!('EAID_', '').gsub!('_', '-')
      ret = '<a href="$element://{' + id + '}"><font color="' + BARVA_ODKAZU_TRIDA + '"><u>' + text + '</u></font></a>'
      vysledek = najdi_identifikator_asociace(trida,atribut)
      if vysledek != nil
        id = vysledek[0]
        text = vysledek[1]
        ret = ret + '.' + '<font color="' + BARVA_ODKAZU_TRIDA + '">' + text + '</font>'
      else
        ret = jmeno
      end
    else
      ret = jmeno
    end  
    ret  
  end  

  def odkaz_na_metodu(jmeno)
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    vnitrek.match('(.+)_(.+)_')
    trida = $1
    metoda = $2
    vysledek = najdi_identifikator_class(trida)
    if vysledek != nil
      id = vysledek[0]
      text = vysledek[1]
      id.gsub!('EAID_', '').gsub!('_', '-')
      ret = '<a href="$element://{' + id + '}"><font color="' + BARVA_ODKAZU_TRIDA + '"><u>' + text + '</u></font></a>'
      vysledek = najdi_identifikator_metoda(trida,metoda)
      if vysledek != nil
        id = vysledek[0]
        text = vysledek[1]
        ret = ret + '.' + '<a href="$feature://' + id + '"><font color="' + BARVA_ODKAZU_TRIDA + '"><u>' + text + '()' + '</u></font></a>' 
      else
        ret = jmeno
      end
    else
      ret = jmeno
    end  
    ret  
  end  


  # na vstupu je odkaz bez hranatych zavorek
  # vraci pole s id a text nebo nil, pokud nenasel
  def najdi_identifikator_uc(text_odkazu)
    return nil unless text_odkazu[0..2] == 'uc_'

    if text_odkazu[3..-1].match('_') then
      text_odkazu[3..-1].match(/([^_]+)(\w+)/)
      stereotyp = $1
      jmeno = $2.gsub('_', ' ').lstrip.rstrip
    else
      stereotyp = ""
      jmeno = text_odkazu[3..-1].lstrip.rstrip
    end  

    if !STEREOTYPY.include?(stereotyp) then
      jmeno = (stereotyp + ' ' + jmeno).lstrip
      stereotyp = ""
    end  

    nodes = @doc.xpath(PREFIX + "/UML:Package[@name = '#{@project_name}']/UML:Namespace.ownedElement/UML:Package[@name='Use Case Model']//UML:UseCase[eq(@name,'#{jmeno}')]", XpathFunctions.new)

    # pokud jsem nasel vice, tak beru prvniho z nich, ktery ma spravny stereotyp
    vysledek = []
    nodes.each do |node|
      ster = node.xpath("UML:ModelElement.stereotype/UML:Stereotype/@name")[0]

      if (ster == nil and stereotyp == "") or XpathFunctions.new.equal(stereotyp, ster)
        vysledek[0] = node['xmi.id']
        vysledek[1] = node['name'] 
        vysledek[1] = ster.content + ' ' + vysledek[1] if ster
        return vysledek
      end
    end

    nil 
  end  

  def najdi_identifikator_bp(text_odkazu)
    return nil unless text_odkazu[0..5] == 'ac_bp_'

    jmeno = text_odkazu[6..-1].gsub('_', ' ').lstrip.rstrip

    nodes = @doc.xpath(PREFIX + "/UML:Package[@name = '#{@project_name}']/UML:Namespace.ownedElement/UML:Package[@name='Business Process Model']//UML:ActionState[eq(@name,'#{jmeno}')]", XpathFunctions.new)

    vysledek = []
    nodes.each do |node|
      vysledek[0] = node['xmi.id']
      vysledek[1] = node['name']
      return vysledek
    end

    nil 
  end  
  
  def najdi_identifikator_class(text_odkazu)
    return nil if text_odkazu[0..2] == 'uc_'
    return nil if text_odkazu[0..2] == 'ac_'
    return nil if text_odkazu.match('_')

    jmeno = text_odkazu.lstrip.rstrip

    nodes = @doc.xpath(PREFIX + "/UML:Package[@name = '#{@project_name}']/UML:Namespace.ownedElement/UML:Package[@name='Class Model']//UML:Class[@name = '#{jmeno}'] | " + PREFIX + "/UML:Package[@name = 'w4cis']/UML:Namespace.ownedElement//UML:Class[@name = '#{jmeno}']")

    vysledek = []
    nodes.each do |node|
      vysledek[0] = node['xmi.id']
      vysledek[1] = jmeno 
      return vysledek
    end

    nil 
  end  

  def najdi_identifikator_atribut(trida, atribut)
    return nil if trida.match('_')
    return nil if atribut.match('_')

    trida = trida.lstrip.rstrip
    atribut = atribut.lstrip.rstrip

    nodes = @doc.xpath(PREFIX + "/UML:Package[@name = '#{@project_name}']/UML:Namespace.ownedElement/UML:Package[@name = 'Class Model']//UML:Class[@name = '#{trida}']//UML:Attribute[@name = '#{atribut}']//UML:TaggedValue[@tag = 'ea_guid'] | " + PREFIX + "/UML:Package[@name = 'w4cis']/UML:Namespace.ownedElement//UML:Class[@name = '#{trida}']//UML:Attribute[@name = '#{atribut}']//UML:TaggedValue[@tag = 'ea_guid']   ")

    vysledek = []
    nodes.each do |node|
      vysledek[0] = node['value']
      vysledek[1] = atribut
      return vysledek
    end

    nil 
  end  

  def najdi_identifikator_asociace(trida, asoc)
    return nil if trida.match('_')
    return nil if asoc.match('_')

    trida = trida.lstrip.rstrip
    asoc = asoc.lstrip.rstrip

    nodes = @doc.xpath(PREFIX + "/UML:Package[@name = '#{@project_name}']/UML:Namespace.ownedElement/UML:Package[@name='Class Model']//UML:Association//UML:TaggedValue[@tag = 'ea_sourceName' and @value='" + trida + "'] | " + PREFIX + "/UML:Package[@name = 'w4cis']/UML:Namespace.ownedElement//UML:Association//UML:TaggedValue[@tag = 'ea_sourceName' and @value='" + trida + "'] ")
    
    vysledek = []
    nodes.each do |node|
      if node.parent.xpath("UML:TaggedValue[@tag = 'rt' and @value='+#{asoc}']")[0] or node.parent.xpath("UML:TaggedValue[@tag = 'ea_targetName' and eq(@value,'#{asoc}')]", XpathFunctions.new)[0]
        vysledek[0] = node['xmi.id']
        vysledek[1] = asoc
        return vysledek
      end  
    end

    nodes = @doc.xpath(PREFIX + "/UML:Package[@name = '#{@project_name}']/UML:Namespace.ownedElement/UML:Package[@name='Class Model']//UML:Association//UML:TaggedValue[@tag = 'ea_targetName' and eq(@value,'#{trida}')] | " + PREFIX + "/UML:Package[@name = 'w4cis']/UML:Namespace.ownedElement//UML:Association//UML:TaggedValue[@tag = 'ea_targetName' and eq(@value,'#{trida}')] ", XpathFunctions.new)
    
    vysledek = []
    nodes.each do |node|
      if node.parent.xpath("UML:TaggedValue[@tag = 'lt' and @value='+#{asoc}']")[0] or node.parent.xpath("UML:TaggedValue[@tag = 'ea_sourceName' and eq(@value,'#{asoc}')]", XpathFunctions.new)[0]
        vysledek[0] = node['xmi.id']
        vysledek[1] = asoc
        return vysledek
      end  
    end
    
    #ted uz to muze byt pouze asociativni trida - spravnost jejich koncu ale netestuju - zjednodusim si to
    nodes = @doc.xpath(PREFIX + "/UML:Package[@name = '#{@project_name}']/UML:Namespace.ownedElement/UML:Package[@name='Class Model']//UML:Class[@name = '#{trida}'] | " + PREFIX + "/UML:Package[@name = 'w4cis']/UML:Namespace.ownedElement//UML:Class[@name = '#{trida}'] ")

    vysledek = []
    nodes.each do |node|
      if node.xpath("UML:ModelElement.taggedValue/UML:TaggedValue[@tag = 'conID']")[0]
        vysledek[0] = node['xmi.id']
        vysledek[1] = asoc
        return vysledek
      end  
    end


    nil 
  end  

  def najdi_identifikator_metoda(trida, metoda)
    return nil if trida.match('_')
    return nil if metoda.match('_')

    trida = trida.lstrip.rstrip
    metoda = metoda.lstrip.rstrip

    nodes = @doc.xpath(PREFIX + "/UML:Package[@name = '#{@project_name}']/UML:Namespace.ownedElement/UML:Package[@name='Class Model']//UML:Class[@name = '#{trida}']//UML:Operation[@name = '#{metoda}']//UML:TaggedValue[@tag = 'ea_guid'] | " + PREFIX + "/UML:Package[@name = 'w4cis']/UML:Namespace.ownedElement//UML:Class[@name = '#{trida}']//UML:Operation[@name = '#{metoda}']//UML:TaggedValue[@tag = 'ea_guid'] ")
    
   
    vysledek = []
    nodes.each do |node|
      vysledek[0] = node['value']
      vysledek[1] = metoda
      return vysledek
    end

    nil 
  end  

end


class XpathFunctions

  def eq(node_set, str_to_match)
    node_set.find_all {|node| equal(node.to_s, str_to_match.to_s) }
  end

  def equal(a,b)
    translate(a.to_s) == translate(b.to_s)
  end  

  def translate(s)
    s.tr('ěĚšŠčČřŘžŽýÝáÁíÍéÉúÚůďĎňŇťŤ-', 'eessccrrzzyyaaiieeuuuddnntt ').downcase
  end  
end


def check_usage
  unless ARGV.length == 3
    puts "Usage: linker.rb project_name input_xml_file output_xml_file"
    exit
  end
end


if $0 == __FILE__
  check_usage
  Linker.new(ARGV[0]).go(ARGV[1], ARGV[2])
end
