# encoding: utf-8

require 'test/unit'
require './linker'
require 'nokogiri'

class TestLinker < Test::Unit::TestCase
  
  def setup
    @linker = Linker.new
    @linker.go('vstup.xml')
    f = File.open("vystup.xml")
    @doc = Nokogiri::XML(f)
    f.close
  end


  def test_vytvoreni_vystupniho_souboru
    assert File.file?('vystup.xml')
  end

  def test_zda_je_to_xmi
    assert !@doc.xpath("/XMI//UML:Model").empty?
  end

  def test_ztucneni_nadpisu
    text = @doc.xpath("//UML:UseCase[@name='Budovy']//UML:TaggedValue[@tag='documentation']/@value")[0]
    assert_not_nil text, "nenalezen text UC 'Budovy'"
    assert_no_match /^==[^=.]+==/, text, 'Nebyly odstraneny == ze zacatku nadpisu'
    assert_match %r|^<b>Předpoklady</b>|, text, 'UC neobsahuje tucny nadpis Předpoklady'  
    assert_match %r|^Pokud něco == něco jiného|, text, 'UC neobsahuje test rovnosti'
  end

 
  def test_najdi_identifikator_uc
    vysledek = @linker.najdi_identifikator_uc('uc_karta_polozka_najmu')
    assert_equal 'EAID_FFD83C53_8290_43a2_B865_0584D2465243', vysledek[0] 
    assert_equal 'karta Položka nájmu', vysledek[1] 
    assert_equal 'EAID_FFD83C53_8290_43a2_B865_0584D2465243', @linker.najdi_identifikator_uc("uc_karta_POLOZKA_nAjmu")[0] 

    vysledek = @linker.najdi_identifikator_uc('uc_provedeni_neceho')
    assert_equal 'Provedení něčeho', vysledek[1] 
    vysledek = @linker.najdi_identifikator_uc('uc_uzavreni')
    assert_equal 'Uzavření', vysledek[1] 
  end

  def test_najdi_identifikator_class
    vysledek = @linker.najdi_identifikator_class('PolozkaNajmu')
    assert_equal 'PolozkaNajmu', vysledek[1] 
  end
  
  
  def test_hyperlinku_na_uc
    text = @doc.xpath("//UML:UseCase[@name='Budovy']//UML:TaggedValue[@tag='documentation']/@value")[0]
    assert_match %r|#0000ff"><u>karta Položka nájmu</u></font></a>|, text, 'UC neobsahuje hyperlink uc_karta_polozka_najmu'  
    assert_match /\[\[uc_co_neexistuje\]\]/, text, 'Toto se nesmi zmenit'
  end  

  
end
