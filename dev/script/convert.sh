echo 'convert start'
cd `dirname $0`
cd ../
coffee -c -o output coffee/warabi.coffee
mv output/warabi.js output/tmp.js
cat output/RectanglePacker.js output/header.js output/tmp.js > output/warabi.jsx
