
#' Cost-Effectiveness Acceptability Curve (CEAC) Plot By Graph Device
#'
#' Choice of base R, \pkg{ggplot2} or \pkg{plotly}.
#' @name ceac_plot_graph
#' 
#' @template args-he
#' @param pos_legend Legend position
#' @param graph_params Aesthetic ggplot parameters
#' @param ... Additional arguments
NULL


#' @rdname ceac_plot_graph
#' @keywords hplot
#' 
ceac_plot_base <- function(he,
                           pos_legend,
                           graph_params,
                           ...)
  UseMethod("ceac_plot_base", he)


#' @rdname ceac_plot_graph
#' @keywords hplot
#' 
ceac_plot_base.pairwise <- function(he,
                                    pos_legend,
                                    graph_params,
                                    ...) {
  ceac_matplot(he,
               pos_legend,
               graph_params,
               "p_best_interv")
}

#' @rdname ceac_plot_graph
#' @keywords hplot
#'
ceac_plot_base.bcea <- function(he,
                                pos_legend,
                                graph_params,
                                ...) {
  ceac_matplot(he,
               pos_legend,
               graph_params,
               "ceac")
}


#' CEAC Matrix Plot
#' 
#' CEAC plot using `matplot` in Base R.
#' 
#' @inheritParams ceac_plot_graph
#' @param ceac `ceac` index in `he`
#' @keywords internal hplot
#' @importFrom graphics matplot legend
#' @md
ceac_matplot <- function(he,
                         pos_legend,
                         graph_params,
                         ceac) {
  
  base_params <- helper_base_params(he, graph_params)
  
  legend_params <- ceac_legend_base(he, pos_legend, base_params)
  
  do.call("matplot", c(list(x = he$k,
                            y = he[[ceac]]),
                       base_params), quote = TRUE)
  
  do.call(legend, legend_params)
}


#' @rdname ceac_plot_graph
#' 
#' @keywords hplot
#' 
ceac_plot_ggplot <- function(he,
                             pos_legend,
                             graph_params, ...)
  UseMethod("ceac_plot_ggplot", he)


#' @rdname ceac_plot_graph
#' @keywords hplot
#' 
ceac_plot_ggplot.pairwise <- function(he,
                                      pos_legend,
                                      graph_params, ...) {
  ceac_ggplot(he,
              pos_legend,
              graph_params,
              "p_best_interv", ...)
}

#' @rdname ceac_plot_graph
#' @keywords hplot
#' 
ceac_plot_ggplot.bcea <- function(he,
                                  pos_legend,
                                  graph_params, ...) {
  ceac_ggplot(he,
              pos_legend,
              graph_params,
              "ceac", ...)
}

#' @rdname ceac_plot_graph
#' @param ceac ceac index in `he`
#' @importFrom scales label_dollar
#' @keywords internal hplot
#' @md
ceac_ggplot <- function(he,
                        pos_legend,
                        graph_params,
                        ceac, ...) {
  
  extra_params <- list(...)
  
  ceac_dat <- he[[ceac]]
  n_lines <- ncol(ceac_dat)
  len_k <- length(he$k)
  
  data_psa <-
    tibble(k = rep(he$k,
                   times = n_lines),
           ceac = c(ceac_dat),
           comparison = as.factor(rep(1:n_lines, each = len_k)))
  
  graph_params <- helper_ggplot_params(he, graph_params)
  legend_params <- make_legend_ggplot(he, pos_legend)
  theme_add <- purrr::keep(extra_params, is.theme)

  ggplot(data_psa, aes(x = .data$k, y = .data$ceac)) +
    geom_line(aes(linetype = .data$comparison,
                  colour = factor(.data$comparison))) +
    theme_ceac() + 
    theme_add +                                            # theme
    scale_y_continuous(limits = c(0, 1)) +
    scale_x_continuous(
      labels = scales::label_dollar(prefix = graph_params$currency)) +
    do.call(labs, graph_params$annot) +                    # text
    do.call(theme, legend_params) +                        # legend
    scale_linetype_manual("",                              # lines
                          labels = graph_params$labels,
                          values = graph_params$line$type) +
    scale_color_manual("",
                       labels = graph_params$labels,
                       values = graph_params$line$color) +
    scale_linewidth_manual("",
                           labels = graph_params$labels,
                           values = graph_params$line$size)
}


#' @rdname ceac_plot_graph
#' 
#' @keywords hplot
#' 
ceac_plot_plotly <- function(he,
                             pos_legend,
                             graph_params, ...)
  UseMethod("ceac_plot_plotly", he)


#' @rdname ceac_plot_graph
#' @keywords hplot
#' 
ceac_plot_plotly.pairwise <- function(he,
                                      pos_legend,
                                      graph_params, ...) {
  ceac_plotly(he,
              pos_legend,
              graph_params,
              "p_best_interv", ...)
}

#' @rdname ceac_plot_graph
#' @keywords hplot
#' 
ceac_plot_plotly.bcea <- function(he,
                                  pos_legend,
                                  graph_params, ...) {
  ceac_plotly(he,
              pos_legend,
              graph_params,
              "ceac", ...)
}

#' @rdname ceac_plot_graph
#' @param ceac ceac index in `he`
#' @importFrom scales label_dollar
#' @keywords internal hplot
#' @md
ceac_plotly <- function(he,
                        pos_legend = "bottomright",
                        graph_params, 
                        ceac, ...) {
  
  complabs = if(ncol(he[[ceac]]) == length(he$interventions)) {
    he$interventions |> unique() 
  } else {
    he$ceac |> colnames()
  }
  
  data.psa <- data.frame(
    k = rep(he$k, he[[ceac]] |> ncol()),
    ceac = he[[ceac]] |> c(),
    comparison = complabs |> as.factor() |> as.numeric() |> sapply(function(x) rep(x, length(he$k))) |> c(),
    single_label = complabs |> as.factor() |> sapply(function(x) rep(x, length(he$k))) |> c()
  )
  
  if (length(complabs) != length(he$interventions)) {
    data.psa$label = paste0(he$interventions[he$ref], " vs ", data.psa$single_label)
  } else {
    data.psa$label = he$interventions[data.psa$comparison]
  }
  # graph_params$line$type <- graph_params$line$type %||% rep_len(1:6, length(complabs))# he$n_comparisons)
  if (length(graph_params$line$type) != length(complabs))
    graph_params$line$type = rep(graph_params$line$type[1], length(complabs))
  
  # opacities
  if (!is.null(graph_params$area$color))
    graph_params$area$color <-
    sapply(graph_params$area$color, function(x)
      ifelse(grepl(pattern = "^rgba\\(", x = x),
             yes = x,
             no = plotly::toRGB(x, 0.4)))
  
  ceac_plot <- plotly::plot_ly(data.psa, x = ~k)
  ceac_plot <-
    plotly::add_trace(
      ceac_plot,
      y = ~ ceac,
      type = "scatter",
      mode = "lines",
      fill = ifelse(graph_params$area$include, "tozeroy", "none"),
      name = ~ label,
      fillcolor = graph_params$area$color,
      color = ~ comparison,
      colors = graph_params$line$color,
      linetype = ~ comparison,
      linetypes = graph_params$line$type)
  
  legend_params <- make_legend_plotly(pos_legend)
  
  ceac_plot <-
    plotly::layout(
      ceac_plot,
      title = graph_params$annot$title,
      xaxis = list(
        hoverformat = ".2f",
        title = graph_params$annot$x),
      yaxis = list(
        title = graph_params$annot$y,
        range = c(0, 1.005)),
      showlegend = he$n_comparisons > 1, 
      legend = legend_params) |>
    plotly::hide_colorbar()
  
  plotly::config(ceac_plot, displayModeBar = FALSE)
}

