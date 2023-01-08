# RNN multi-purpose text classifier by scratch
For use in parseing out inline code excerpts


### CHAR TABLE
- each char is represented as 96-d vector

|CODE|CHAR|CODE|CHAR|CODE|CHAR|CODE|CHAR|CODE|CHAR|CODE|CHAR
|---|---|---|---|---|---|---|---|---|---|---|---
|00|\[SPACE\]|10|0|20|@|30|P|40|\`|50|p
|01|!|11|1|21|A|31|Q|41|a|51|q
|02|"|12|2|22|B|32|R|42|b|52|r
|03|#|13|3|23|C|33|S|43|c|53|s
|04|$|14|4|24|D|34|T|44|d|54|t
|05|%|15|5|25|E|35|U|45|e|55|u
|06|&|16|6|26|F|36|V|46|f|56|v
|07|'|17|7|27|G|37|W|47|g|57|w
|08|(|18|8|28|H|38|X|48|h|58|x
|09|)|19|9|29|I|39|Y|49|i|59|y
|0a|\*|1a|P|2a|J|3a|Z|4a|j|5a|z
|0b|+|1b|;|2b|K|3b|\[|4b|k|5b|{
|0c|,|1c|<|2c|L|3c|\\|4c|l|5c|\|
|0d|-|1d|=|2d|M|3d|\]|4d|m|5d|}
|0e|.|1e|>|2e|N|3e|^|4e|n|5e|\~
|0f|/|1f|?|2f|O|3f|\_|4f|o|5f|\[NEWLINE\]


## Data sources
text taken from https://www.gutenberg.org/cache/epub/69739/pg69739-images.html