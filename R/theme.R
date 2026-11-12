#' A clean ggplot2 theme for synthcheck graphics
#'
#' The theme used by every synthcheck plot (the same as `theme_mirtverse()`
#' in mirtverse).
#'
#' @param base_size base font size.
#' @return A ggplot2 theme.
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_synthcheck()
#' @export
theme_synthcheck <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold", hjust = 0),
      plot.title = ggplot2::element_text(face = "bold"),
      plot.title.position = "plot",
      legend.position = "bottom")
}
