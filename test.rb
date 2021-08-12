require "minitest/autorun"
require "nokogiri"
require 'net/http'

# tag::test_isx_fajla[]
describe "The source file " do
  before do
    @isxodnyj_fajl = File.read("statqya.adoc")
  end
  it "should not contain more than one line break" do
    assert_nil @isxodnyj_fajl.match('\n\n\n')
  end
  it "should not contain whitespaces" do
    assert_nil @isxodnyj_fajl.match(' \n')
  end
  it "should contain only linux line breaks" do
    assert_nil @isxodnyj_fajl.match('\r\n')
  end
  it "should contain empty lines after headings" do
    assert_nil @isxodnyj_fajl.match('^[=]{2,}.*\n[^\n]')
  end
end
# end::test_isx_fajla[]

# tag::test_fin_describe[]
describe "Final document " do
# end::test_fin_describe[]
# tag::ne_soderzhit_orf_oshibok[]
  it "has no typos " do
    assert_equal File.read('misspelled-list'), ''
  end
# end::ne_soderzhit_orf_oshibok[]
# tag::bez_perenosov_strok[]
  it "is not based on paragraphs with line breaks " do
    assert_nil File.read('statqya.break-line').match('[^\n^+][\n][^\n]')
  end
# end::bez_perenosov_strok[]
# tag::russian_pretty[]
  it "more or less pretty as a russian text" do
    assert_nil File.read('statqya.spell').match('и т\.п\.'), "и{nbsp}т.п."
    assert_nil File.read('statqya.spell').match('и т\.д\.'), "и{nbsp}т.д."
    assert_nil File.read('statqya.spell').match('[Нн]ужн'), "Нужн... -> Необходим..."
    assert_nil File.read('statqya.spell').match('[Оо]однако'), "Однако --> ?"
    assert_nil File.read('statqya.spell').match('[ \(](Вы|Вас|Вам)[^а-я]'), "вы, вас, вам"
    assert_nil File.read('statqya.spell').match('Если[^\.]*, то'),
      "Если.. то, -- не программирование"
  end
# end::russian_pretty[]
# tag::bez_oshibok_asciidoctor[]
  it "has no Asciidoctor errors " do
    assert_equal File.read('asciidoctor_log'), ''
  end
# end::bez_oshibok_asciidoctor[]
# tag::bez_oshibok_struktura[]
  it "has correct structure" do
    xsd = Nokogiri::XML::Schema(File.read("statqya.xsd"))
    doc = Nokogiri::XML(File.read("statqya.xml"))
    assert_equal xsd.validate(doc).join("\n"), ''
  end
# end::bez_oshibok_struktura[]
# tag::bez_oshibok_struktura_xpath[]
  it "contains only list items with only one paragraph per item" do
    doc = Nokogiri::XML(File.read("statqya.xml"))
    assert_equal doc.xpath("//db:listitem[count(db:simpara) != 1]",
      'db' => 'http://docbook.org/ns/docbook').size, 0
  end
# end::bez_oshibok_struktura_xpath[]
# tag::bez_oshibok_ssyhlki[]
  it "has no 404 hyperlinks" do
    doc = Nokogiri::XML(File.read("statqya.xml"))
    erroneous_links = ''
    doc.xpath("//db:link/@xl:href",
        'db' => 'http://docbook.org/ns/docbook',
        'xl' => 'http://www.w3.org/1999/xlink').each do |link_href|
      begin
        puts link_href.to_s
        url = URI.parse(link_href.to_s)
        req = Net::HTTP.new(url.host, url.port)
        req.use_ssl = (url.scheme == "https")
        res = req.request_head(url.path)
      rescue  SocketError => e
        erroneous_links += link_href.to_s + "(#{e})\n"
      end
    end
    assert_equal erroneous_links, ''
  end
# end::bez_oshibok_ssyhlki[]
# tag::estq_odt[]
  it "has an odt output" do
    assert File.exists?("statqya.odt")
  end
# end::estq_odt[]
# tag::test_fin_describe_end[]
end
# end::test_fin_describe_end[]
