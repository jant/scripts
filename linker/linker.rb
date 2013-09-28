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

class Linker

  def go(file)
    FileUtils.cp('vstup.xml', 'vystup.xml')

    File.open("vystup.xml", 'r') {|f| @doc = Nokogiri::XML(f)}
    ztucneni_vsech_nadpisu
    hyperlinky_na_uc
    hyperlinky_na_class
    File.open("vystup.xml", 'w') {|f| f.print @doc.to_xml}
  end

  def ztucneni_vsech_nadpisu
    nodes = @doc.xpath("//UML:UseCase//UML:TaggedValue[@tag='documentation']/@value")
    
    nodes.each do |node|
      node.content = node.content.gsub(/^==([^=.]+)==/) do |m|
        '<b>' + $1.lstrip.rstrip + '</b>'
      end  
    end
  end

  def hyperlinky_na_uc
    nodes = @doc.xpath("//UML:UseCase//UML:TaggedValue[@tag='documentation']/@value")
    
    nodes.each do |node|
      node.content = node.content.gsub(/\[\[.+\]\]/) { |m| odkaz_na_uc(m)}
    end

  end

  def hyperlinky_na_class
    # TODO sem pridat krome UC i notes trid a atributu a BPM
    nodes = @doc.xpath("//UML:UseCase//UML:TaggedValue[@tag='documentation']/@value")
    
    nodes.each do |node|
      node.content = node.content.gsub(/\[\[.+\]\]/) { |m| odkaz_na_class(m)}
    end

  end
  
  def odkaz_na_uc(jmeno)
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    vysledek = najdi_identifikator_uc(vnitrek)
    if vysledek != nil
      id = vysledek[0]
      text = vysledek[1]
      id.gsub!('EAID_', '').gsub!('_', '-')
      vysledek = '<a href="$element://{' + id + '}"><font color="#0000ff"><u>' + text + '</u></font></a>'
    else
      vysledek = jmeno
    end  
    vysledek  
  end  

  def odkaz_na_class(jmeno)
    vnitrek = jmeno.lstrip.rstrip.gsub('[[', '').gsub(']]', '')
    vysledek = najdi_identifikator_class(vnitrek)
    if vysledek != nil
      id = vysledek[0]
      text = vysledek[1]
      id.gsub!('EAID_', '').gsub!('_', '-')
      vysledek = '<a href="$element://{' + id + '}"><font color="#ff0080"><u>' + text + '</u></font></a>'
    else
      vysledek = jmeno
    end  
    vysledek  
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
      vysledek[1] = node['name'] 
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


