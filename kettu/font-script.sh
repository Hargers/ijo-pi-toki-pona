#!/bin/bash
#A script reused fom a previous project that downloads a Discord client, unzips it, takes its fonts, and merges them with nasin nanpa tan anpa nanpa. Outputs merged font files and deletes the leftovers.
#This one also merges a later beta release of the font that has radicals added.

requirements=("wget" "fontforge" "unzip")
for i in ${requirements[@]}; do
        if ! hash "$i" &>/dev/null; then missing+=($i); fi
done
if [[ -v missing ]]; then
        for i in ${missing[@]}-1; do echo -e "This script requires '${missing[i]}'. '${missing[i]}' was not found in PATH."; done
        echo "Aborting."; exit 1;
fi

enmityLink="https://github.com/enmity-mod/tweak/releases/latest/download/Enmity.ipa"

wget -O nasin-nanpa.otf $(wget -q -O - https://api.github.com/repos/ETBCOR/nasin-nanpa/releases/latest | awk '/browser_download_url/ && $0 !~ /Helvetica/ && $0 !~ /UCSUR/ {print $2}' | sed 's/\"//g') -q --show-progress || { echo >&2 "Failed to download font nasin-nanpa"; exit 1; }
wget -O nasin-nanpa-5beta3.otf "https://github.com/etbcor/nasin-nanpa/releases/download/n5.0.0-beta.3/nasin-nanpa-5.0.0-beta.3.otf" -q --show-progress || { echo >&2 "Failed to download font nasin-nanpa 5 beta 3"; exit 1; }
wget $enmityLink -q --show-progress || { echo >&2 "Failed to download Enmity"; exit 1; }

if [ -f ligatures.psv ] && rows=$(awk 'END { print NR }' ligatures.psv) && [ $rows -gt 0 ]; then
	echo "Saving ligatures"
	ligatureScript+="AddLookup(\"'liga' Standard Ligatures in Latin lookup 15\",\"GSUB_ligature\",0,[[\"liga\",[[\"dflt\",[\"dflt\",\"latn\"]],[\"latn\",[\"dflt\"]]]]],\"'rand' Randomize in Latin lookup 2\");"
	ligatureScript+="AddLookupSubtable(\"'liga' Standard Ligatures in Latin lookup 15\",\"'liga' Standard Ligatures in Latin lookup 15 subtable\");"
	for ((row=1; row<=rows; row++)); do
		fromLookup=$(awk -v row="$row" -v column="1" -F '|' 'NR==row {print $column}' ligatures.psv)
		if [[ $fromLookup == \#* ]]; then continue; fi
		glyph=$(awk -v row="$row" -v column="2" -F '|' 'NR==row {print $column}' ligatures.psv)
		sourceGlyphs=$(awk -v row="$row" -v column="3" -F '|' 'NR==row {print $column}' ligatures.psv)
		ligatureScript+="Select(\"$glyph\");"
		ligatureScript+="RemovePosSub(\"$fromLookup\");"
		ligatureScript+="AddPosSub(\"'liga' Standard Ligatures in Latin lookup 15 subtable\", \"$sourceGlyphs\");"
	done
else echo "No saved ligatures"; fi

fontforge -lang=ff -c "Open(\"nasin-nanpa-5beta3.otf\");SelectMore(\"U+F1C80\");SelectMore(\"U+F1C81\");SelectMore(\"U+F1C82\");SelectMore(\"U+F1C83\");SelectMore(\"U+F1C84\");SelectMore(\"U+F1C85\");SelectMore(\"U+F1C86\");SelectMore(\"U+F1C87\");SelectMore(\"U+F1C88\");SelectMore(\"U+F1C89\");SelectMore(\"U+F1C8A\");SelectMore(\"U+F1C8B\");SelectMore(\"U+F1C8C\");SelectMore(\"U+F1C8D\");SelectMore(\"U+F1C8E\");SelectMore(\"U+F1C8F\");SelectMore(\"U+F1C90\");SelectMore(\"U+F1C91\");SelectMore(\"U+F1C92\");SelectMore(\"U+F1C93\");SelectMore(\"U+F1C94\");SelectMore(\"U+F1C95\");SelectMore(\"U+F1C96\");SelectMore(\"U+F1C97\");SelectMore(\"U+F1C98\");SelectMore(\"U+F1C99\");SelectMore(\"U+F1C9A\");SelectMore(\"U+F1C9B\");SelectMore(\"U+F1C9C\");SelectMore(\"U+F1C9D\");SelectMore(\"U+F1C9E\");SelectMore(\"U+F1C9F\");SelectInvert();DetachAndRemoveGlyphs();Generate(\"nasin-nanpa-radicals.otf\")"
fontforge -lang=ff -c "Open(\"nasin-nanpa.otf\"); $ligatureScript RemoveLookup(\"'liga' Standard Ligatures in Latin lookup 0\"); RemoveLookup(\"'liga' Standard Ligatures in Latin lookup 1\"); RemoveLookup(\"'liga' Standard Ligatures in Latin lookup 3\"); MergeFonts(\"nasin-nanpa-radicals.otf\"); Generate(\"nasin-nanpa.otf\")"

unzip Enmity.ipa

for font in Payload/Discord.app/*.ttf; do
	echo "$font -> ${font%???}otf"
	fontforge -lang=ff -c "Open(\"$font\");
	MergeFonts(\"nasin-nanpa.otf\");
	Generate(\"${font%???}otf\")"
done

mkdir output
mv Payload/Discord.app/*.otf output/
echo "Fonts output to output/ folder"
echo "Cleaning up..."
rm -r Payload Enmity.ipa nasin-nanpa-radicals.otf nasin-nanpa.otf nasin-nanpa-5beta3.otf
echo "Done."
