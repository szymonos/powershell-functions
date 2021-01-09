# Regular Expressions

[Basic Syntax | Markdown Guide](https://www.markdownguide.org/basic-syntax)

[Regular Expressions Cheat Sheet by DaveChild](https://www.cheatography.com/davechild/cheat-sheets/regular-expressions/)

***

## Remove duplicated words

[VSCode find and replace using regex](https://itnext.io/vscode-find-and-replace-regex-super-powers-c7f8be0fa80f)

``` markdown
\b(\w+)\s+\1\b
\b(\w+)(?:(?![\n\r])\s)+\1\b
----replace----
$1
```

## Find Missing collation

``` RegEx
\[?(var)?char\]?\s*\(\d+\)\s+(?!COLLATE)
```

## Find all [char] (2), char  (2) etc

``` RegEx
(cono(?!lang)\w*\]?) +(\[?(n?var)?char\]? *)\(2\)
(\[?\w*(cid)\w*\]? +\[?)(char\]? *)\(10\)
(\[?\w*(?<!vm)(oid|order)(?!type|cono)\w*\]? +\[?)(var)(char\]? *)\((? !10)\d\d\)
----replace----
$1 $2(4)
(cono[\]]? *[\[]?[nvar]*char[\]]? *\()2
```

***

## Replace all foreign key references schema ac

``` RegEx
(references [\[]?)ac
----replace----
$1dbo
```

## replace all like *dsq* columns from (var)char (3/4) to varchar(10)

``` RegEx
(\[?\w*dsq\w*\]? +\[?)(n?var)?(char\] *)\([3-4]\)
----replace----
$1var$3(10)
```

## replace all keys names

``` RegEx
(alter table.*add +constraint +[\[]?)(\w+)([\]]?.*)
----replace----
$1$2_DMS$3
```

## remove all indexes

``` RegEx
CREATE *(\w*)? *\w* *INDEX.*
```

## Lookarounds

- **?=** is positive lookahead and **?!** is negative lookahead
- **?<=** is positive lookbehind and **?<!** is negative lookbehind

## remove roles except LangService

``` RegEx
GRANT +[a-z]+ +ON +\[.+\].\[.+\] +TO +\[(?!LangService)[\w]+_role\]
```

## look for all ownerid excep topownerid

``` RegEx
(?<!top)ownerid\]? +\[?(var)?char\]? *\(8\)
```

## remove use xlink

``` RegEx
(?<!--)use +[\[]?xlink
```

## exclude strings with LangId

``` RegEx
[^LangId] char\(2\)
----replace----
$14
```

## files to exclude (Case sensitive!)

``` RegEx
*DataSync*
```

## Escape special characters in PowerShell

``` PowerShell
[Regex]::Escape($regexStr)
```
