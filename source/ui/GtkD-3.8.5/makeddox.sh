#!/bin/sh

mkdir -p ddox/temp

echo "Generating JSON file for modules"

echo "MODULES =" > modules.ddoc ;grep -h -e "^module" generated/gtkd/* -r | sort -u | sed 's/;//' | sed 's/\r//' |  sed 's/module \(.*\)$/\t$(MODULE \1)/' >> modules.ddoc
grep -h -e "^module" generated/sourceview/* -r | sort -u | sed 's/;//' | sed 's/\r//' |  sed 's/module \(.*\)$/\t$(MODULE \1)/' >> modules.ddoc
grep -h -e "^module" generated/vte/* -r | sort -u | sed 's/;//' | sed 's/\r//' |  sed 's/module \(.*\)$/\t$(MODULE \1)/' >> modules.ddoc
grep -h -e "^module" generated/gstreamer/* -r | sort -u | sed 's/;//' | sed 's/\r//' |  sed 's/module \(.*\)$/\t$(MODULE \1)/' >> modules.ddoc
grep -h -e "^module" generated/peas/* -r | sort -u | sed 's/;//' | sed 's/\r//' |  sed 's/module \(.*\)$/\t$(MODULE \1)/' >> modules.ddoc

dmd -o- -D -X -Xfddox/docs.json -Ddddox/temp \
	generated/gtkd/gtk/*.d generated/gtkd/gtk/c/*.d  generated/gtkd/gtkc/*.d generated/gtkd/gtkd/*.d generated/gtkd/glib/*.d generated/gtkd/glib/c/*.d generated/gtkd/gio/*.d \
	generated/gtkd/gio/c/*.d generated/gtkd/gdk/*.d generated/gtkd/gdk/c/*.d generated/gtkd/gobject/*.d generated/gtkd/gobject/c/*.d \
	generated/gtkd/gthread/*.d generated/gtkd/gthread/c/*.d generated/gtkd/atk/*.d generated/gtkd/atk/c/*.d generated/gtkd/pango/*.d generated/gtkd/pango/c/*.d \
	generated/gtkd/cairo/*.d generated/gtkd/cairo/c/*.d generated/gtkd/gdkpixbuf/*.d generated/gtkd/gdkpixbuf/c/*.d generated/gtkd/rsvg/*.d generated/gtkd/rsvg/c/*.d \
	generated/sourceview/gsv/*.d generated/sourceview/gsv/c/*.d generated/sourceview/gsvc/*.d \
	generated/vte/vtec/*.d  generated/vte/vte/*.d generated/vte/vte/c/*.d \
	generated/gstreamer/gstreamer/*.d generated/gstreamer/gstreamer/c/*.d generated/gstreamer/gstinterfaces/*.d generated/gstreamer/gstinterfaces/c/*.d generated/gstreamer/gstreamerc/*.d \
	generated/gstreamer/gst/mpegts/*.d generated/gstreamer/gst/mpegts/c/*.d generated/gstreamer/gst/base/*.d generated/gstreamer/gst/base/c/*.d generated/gstreamer/gst/app/*.d generated/gstreamer/gst/app/c/*.d \
	generated/peas/peas/*.d generated/peas/peas/c/*.d generated/peas/peasc/*.d -op

# Delete all html files generated by D ddocs
rm -rf ddox/temp/*

#insert a fake comment for all modules so that ddox doesn't filter out the modules
echo "Adding comment to modules"
sed -i 's/"kind" : "module",/"kind" : "module", "comment" : " ",/g' ddox/docs.json

#Fix problem with unicode quotes by replacing them with ASCII quotes
echo Replacing unicode double and single quotes with ASCII equivalent
sed -i 's/“/\&quot;/g' ddox/docs.json
sed -i 's/”/\&quot;/g' ddox/docs.json
sed -i 's/’/\&#39;/g' ddox/docs.json

#Escape tags that are causing problems.
echo Escaping gtk.Builder tags.
sed -i 's/<template\([^>]*\)>/\&lt;template\1\&gt;/g' ddox/docs.json
sed -i 's/<\/template>/\&lt;\/template\&gt;/g' ddox/docs.json
sed -i 's/<interface\([^>]*\)>/\&lt;interface\1\&gt;/g' ddox/docs.json
sed -i 's/<\/interface>/\&lt;\/interface\&gt;/g' ddox/docs.json
sed -i 's/<object\([^>]*\)>/\&lt;object\1\&gt;/g' ddox/docs.json
sed -i 's/<\/object>/\&lt;\/object\&gt;/g' ddox/docs.json
sed -i 's/<child\([^>]*\)>/\&lt;child\1\&gt;/g' ddox/docs.json
sed -i 's/<\/child>/\&lt;\/child\&gt;/g' ddox/docs.json
sed -i 's/<property\([^>]*\)>/\&lt;property\1\&gt;/g' ddox/docs.json
sed -i 's/<\/property>/\&lt;\/property\&gt;/g' ddox/docs.json

echo "Convert UTF-8 to ASCII for everything else"
mv ddox/docs.json ddox/docs_utf8.json
iconv -f utf8 -t ascii -c ddox/docs_utf8.json > ddox/docs.json

# Filter out everything except public members
dub run ddox -- filter ddox/docs.json --only-documented --min-protection Public

# Use dub to run ddox and generate offline ddox documentation
dub run ddox -- generate-html --navigation-type=moduleTree ddox/docs.json ddox