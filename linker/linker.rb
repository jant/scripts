# encoding: utf-8

require 'fileutils'
 require 'nokogiri'

STEREOTYPY = [
"prehled",
"karta",
"evidence",
"zalozeni",
"zmena",
"zrusení",
"urceni",
"sestava"
]

BARVA_ODKAZU_UC = '#ff0080'
BARVA_ODKAZU_TRIDA = '#0000ff'

class Linker

  def go(file)
    FileUtils.cp('vstup.xml', 'vystup.xml')

    File.open("vystup.xml", 'r') {|f| @doc = Nokogiri::XML(f)}
    transformace_notes
    File.open("vystup.xml", 'w') {|f| f.print @doc.to_xml}
  end

  def transformace_notes
    nodes = @doc.xpath("//UML:ModelElement.taggedValue//UML:TaggedValue[@tag='documentation' or @tag='description']/@value")
    nodes.each do |node|
      # ztucneni titulku
      node.content = node.content.gsub(/^==([^=.]+)==/) { |m| '<b>' + $1.lstrip.rstrip + '</b>' }  
      # vyrobeni odkazu
      node.content = node.content.gsub(/\[\[\w+\]\]/) { |m| odkaz(m)}
    end
  end  

  def odkaz(jmeno) 
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    ret = jmeno
    if vnitrek[0..2] == 'uc_'
      ret = odkaz_na_uc(jmeno)
    else 
      if vnitrek.match('_') 
        if vnitrek[-1,1] == '_'
          ret = odkaz_na_metodu(jmeno)
        else  
          ret = odkaz_na_atribut(jmeno)
          if ret[0..1] == '[['
            ret = odkaz_na_asociaci(jmeno)
          end  
        end  
      else 
        ret = odkaz_na_class(jmeno)
      end  
    end    
    ret
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

    nodes = @doc.xpath("//UML:UseCase[eq(@name,'#{jmeno}')]", XpathFunctions.new)

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

  def najdi_identifikator_class(text_odkazu)
    return nil if text_odkazu[0..2] == 'uc_'
    return nil if text_odkazu.match('_')

    jmeno = text_odkazu.lstrip.rstrip

    nodes = @doc.xpath("//UML:Class[@name = '#{jmeno}']")

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

    nodes = @doc.xpath("//UML:Class[@name = '#{trida}']//UML:Attribute[@name = '#{atribut}']//UML:TaggedValue[@tag = 'ea_guid']")

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

    nodes = @doc.xpath("//UML:Association//UML:TaggedValue[@tag = 'ea_sourceName' and @value='" + trida + "']")

    vysledek = []
    nodes.each do |node|
      if node.parent.xpath("UML:TaggedValue[@tag = 'rt' and @value='+" + asoc + "']")[0] or node.parent.xpath("UML:TaggedValue[@tag = 'ea_targetName' and eq(@value,'#{asoc}')]", XpathFunctions.new)[0]
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

    nodes = @doc.xpath("//UML:Class[@name = '#{trida}']//UML:Operation[@name = '#{metoda}']//UML:TaggedValue[@tag = 'ea_guid']")

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
    s.tr('ěĚšŠčČřŘžŽýÝáÁíÍéÉúÚůďĎňŇťŤ', 'eessccrrzzyyaaiieeuuuddnntt').downcase
  end  
end


