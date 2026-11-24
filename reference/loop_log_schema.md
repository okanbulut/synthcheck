# The log of the item-revision loop

`loop_log_schema()` lists every table and column that
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)
logs, with its type and meaning. The tables share `run_id` (one per run,
so replications can be stacked) and, except `runs`, `round`. With
`output`, each table is written as `<table>.csv`, and
[`read_loop()`](https://www.okanbulut.com/synthcheck/reference/read_loop.md)
reads them back with these types.

## Usage

``` r
loop_log_schema(table = NULL)
```

## Arguments

- table:

  optional table name to show only its columns.

## Value

A tibble with `table`, `column`, `type` and `description`.

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md),
[`read_loop()`](https://www.okanbulut.com/synthcheck/reference/read_loop.md)

## Examples

``` r
loop_log_schema("edits")
#> # A tibble: 16 × 4
#>    table column        type      description                                    
#>    <chr> <chr>         <chr>     <chr>                                          
#>  1 edits run_id        character Name of the run.                               
#>  2 edits round         integer   Round whose checks prompted the edit; it takes…
#>  3 edits item          character Item edited (the new name for an added item).  
#>  4 edits action        character reword, rekey, drop, add or keep.              
#>  5 edits old_statement character Wording before the edit.                       
#>  6 edits new_statement character Wording after the edit.                        
#>  7 edits old_reverse   logical   Key before the edit.                           
#>  8 edits new_reverse   logical   Key after the edit.                            
#>  9 edits scale         character Scale of the item.                             
#> 10 edits rationale     character Why the reviser made the edit.                 
#> 11 edits cites         character Checks the edit responds to, separated by comm…
#> 12 edits cites_flagged logical   Were all cited checks flagged on this item in …
#> 13 edits resolved      logical   Are the cited checks (or, with none cited, all…
#> 14 edits similarity    numeric   Word overlap (Jaccard) of the old and new word…
#> 15 edits applied       logical   Was the edit applied? FALSE for unknown items …
#> 16 edits note          character Why an edit was not applied.                   
```
