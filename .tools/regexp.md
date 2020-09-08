# Regular expressions examples

[Regular Expressions Cheat Sheet by DaveChild](https://www.cheatography.com/davechild/cheat-sheets/regular-expressions/)

## Find Missing collation

``` RegEx
\[?(var)?char\]? *\(\d+\) +(?!COLLATE)
```

## Find all [char] (2), char  (2) etc

``` RegEx
(cono(?!lang)\w*\]?) +(\[?(n?var)?char\]? *)\(2\)
(\[?\w*(cid)\w*\]? +\[?)(char\]? *)\(10\)
(\[?\w*(?<!vm)(oid|order)(?!type|cono)\w*\]? +\[?)(var)(char\]? *)\((? !10)\d\d\)
```

REPLACE

``` RegEx
$1 $2(4)
(cono[\]]? *[\[]?[nvar]*char[\]]? *\()2
```

***

## Replace all foreign key references schema ac

``` RegEx
(references [\[]?)ac
```

REPLACE

``` RegEx
$1dbo
```

***

## replace all like *dsq* columns from (var)char (3/4) to varchar(10)

``` RegEx
(\[?\w*dsq\w*\]? +\[?)(n?var)?(char\] *)\([3-4]\)
```

REPLACE

``` RegEx
$1var$3(10)
```

***

## replace all keys names

``` RegEx
(alter table.*add +constraint +[\[]?)(\w+)([\]]?.*)
```

REPLACE

``` RegEx
$1$2_DMS$3
```

***

## remove all indexes

``` RegEx
CREATE *(\w*)? *\w* *INDEX.*
```

***

## Lookarounds

**?=** is positive lookahead and **?!** is negative lookahead

## remove roles except LangService

``` RegEx
GRANT +[a-z]+ +ON +\[.+\].\[.+\] +TO +\[(?!LangService)[\w]+_role\]
```

**?<=** is positive lookbehind and **?<!** is negative lookbehind

## look for all ownerid excep topownerid

``` RegEx
(?<!top)ownerid\]? +\[?(var)?char\]? *\(8\)
```

## remove use xlink

``` RegEx
(?<!--)use +[\[]?xlink
```

***

## exclude strings with LangId

``` RegEx
[^LangId] char\(2\)
```

REPLACE

``` RegEx
$14
```

***

## files to exclude (Case sensitive!)

``` RegEx
*DataSync*
```

***

## Escape special characters in strings

``` PowerShell
[Regex]::Escape($regexStr)
```

***
[Basic Syntax | Markdown Guide](https://www.markdownguide.org/basic-syntax)
