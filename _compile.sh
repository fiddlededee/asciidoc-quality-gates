#!/bin/bash
cd "$(dirname "$0")"
rm target -r
mkdir target
cp {statqya.adoc,template_s.fodt,slim,dict,_compile.sh,statqya.xsd,xml.xsd,test.rb,sidi-i-pishi-pravilqno.png} target -r
cd target
echo aspell
# tag::spell_asciidoctor[]
docker run --rm -v $(pwd):/documents/ curs/asciidoctor-od asciidoctor \
  statqya.adoc -b spell -o statqya.spell -T slim/base -T slim/spell
cat statqya.spell | sed "s/-/ /g" | \
  aspell --master=ru --personal=./dict list > misspelled-list
# end::spell_asciidoctor[]
echo break lines
docker run --rm -v $(pwd):/documents/ curs/asciidoctor-od asciidoctor statqya.adoc \
  -b break-line -o statqya.break-line -T slim/base -T slim/break-line

echo docbook
# tag::docbook_asciidoctor[]
docker run --rm -v $(pwd):/documents/ curs/asciidoctor-od asciidoctor \
  statqya.adoc -b docbook -v 2> asciidoctor_log
# end::docbook_asciidoctor[]

echo odt_test
docker run --rm -v $(pwd):/documents/ curs/asciidoctor-od a-od-pre -r asciidoctor-mathematical -r asciidoctor-diagram test.adoc -o pre.xml --trace
echo odt
docker run --rm -v $(pwd):/documents/ curs/asciidoctor-od a-od statqya.adoc odt template_s.fodt

echo pdf
docker run --rm -v $(pwd):/documents/ curs/asciidoctor-od a-od statqya.adoc pdf template_s.fodt

echo html
docker run --rm -v $(pwd):/documents/ curs/asciidoctor-od asciidoctor \
  statqya.adoc -o index.html

echo make md
docker run --rm -v $(pwd):/data/ pandoc/core -f docbook -t markdown -s statqya.xml -o statqya.md --wrap=none --atx-headers

# Makrdown and Markdown are different languages
sed  -i 's/{[#][a-zа-я_]*}//g' statqya.md
sed  -i 's/---/—/g' statqya.md
sed  -i 's/^$/\<cut\/\>/g' statqya.md
sed  -i 's/\[\(.*\)\]{\.no-spell}/\1/' statqya.md

echo testing
docker run --rm -v $(pwd):/documents/ curs/asciidoctor-od ruby test.rb

mkdir out
cp {statqya.odt,statqya.pdf,statqya.md,index.html} out