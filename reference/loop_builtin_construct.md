# Ready-made constructs for the item-revision loop

`loop_builtin_construct()` returns a
[`loop_construct()`](https://www.okanbulut.com/synthcheck/reference/loop_construct.md)
that is ready to use as the target of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).

## Usage

``` r
loop_builtin_construct(name = "financial_wellbeing", ...)
```

## Arguments

- name:

  the construct: `"financial_wellbeing"`.

- ...:

  arguments of
  [`loop_construct()`](https://www.okanbulut.com/synthcheck/reference/loop_construct.md)
  that replace the defaults, for example `n_per_scale`, `population` or
  `scale`.

## Value

An object of class `sc_construct_spec`.

## Details

**`"financial_wellbeing"`.** Financial well-being as defined by the
Consumer Financial Protection Bureau (2015), with its four elements as
scales:

- `control`: Control over one's finances: Paying bills on time, not
  having unmanageable debt and being able to make ends meet.

- `cushion`: A financial cushion against unexpected expenses and
  emergencies, such as savings, health insurance, good credit and
  friends or family who can help.

- `goals`: Financial goals, such as paying off student loans or saving
  for retirement, and being on track to meet them.

- `freedom`: Being able to make choices that allow one to enjoy life,
  such as a vacation, a meal out, going back to school or working less
  to spend time with family.

Its stopping rule adds two parts to the defaults of
[`loop_criterion()`](https://www.okanbulut.com/synthcheck/reference/loop_criterion.md):
A marginal reliability of at least 0.80 in every scale (from
[`loop_irt()`](https://www.okanbulut.com/synthcheck/reference/loop_irt.md))
and parallel analysis finding four dimensions, one per scale.

## References

Consumer Financial Protection Bureau. (2015). *Financial well-being: The
goal of financial education*. Washington, DC: CFPB.

## See also

[`loop_construct()`](https://www.okanbulut.com/synthcheck/reference/loop_construct.md),
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)

## Examples

``` r
loop_builtin_construct("financial_wellbeing")
#> Construct "Financial well-being": 4 scales, 6 items each, answers 1 to 5.
#> A state in which a person can fully meet current and ongoing financial obligations, can feel secure in their financial future, and is able to make choices that allow them to enjoy life. 
#>   control: Having control over one's finances: Being able to pay bills on time, not having unmanageable debt, and being able to make ends meet.
#>   cushion: Having a financial cushion against unexpected expenses and emergencies: Savings, health insurance and good credit, and being able to rely on friends and family for financial help, which increase the capacity to absorb a financial shock.
#>   goals: Having financial goals, such as paying off student loans within a certain number of years or saving a particular amount toward retirement, and being on track to meet them.
#>   freedom: Being able to make choices that allow one to enjoy life, such as taking a vacation, enjoying a meal out now and then, going back to school for an advanced degree, or working less to spend more time with family.
loop_builtin_construct("financial_wellbeing", n_per_scale = 8, population = "adults in Canada")
#> Construct "Financial well-being": 4 scales, 8 items each, answers 1 to 5.
#> A state in which a person can fully meet current and ongoing financial obligations, can feel secure in their financial future, and is able to make choices that allow them to enjoy life. 
#>   control: Having control over one's finances: Being able to pay bills on time, not having unmanageable debt, and being able to make ends meet.
#>   cushion: Having a financial cushion against unexpected expenses and emergencies: Savings, health insurance and good credit, and being able to rely on friends and family for financial help, which increase the capacity to absorb a financial shock.
#>   goals: Having financial goals, such as paying off student loans within a certain number of years or saving a particular amount toward retirement, and being on track to meet them.
#>   freedom: Being able to make choices that allow one to enjoy life, such as taking a vacation, enjoying a meal out now and then, going back to school for an advanced degree, or working less to spend more time with family.
```
