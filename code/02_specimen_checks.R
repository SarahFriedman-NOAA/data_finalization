## Stats to detect outliers --------------------------------------------------

# length outliers
length_stats <- new_lengths %>%
  dplyr::right_join(new_haul) %>%
  dplyr::bind_rows(old_lengths) %>%
  dplyr::group_by(species_code) %>%
  dplyr::mutate(outlier = abs(length - median(length, na.rm = T)) > (4 * mad(length, na.rm = T)) & year == this_year) %>%
  dplyr::left_join(species_codes, by = join_by(species_code))

length_outliers <- length_stats %>%
  dplyr::filter(outlier) %>%
  dplyr::arrange(species_code) %>%
  dplyr::select(cruise, region, vessel= vessel_id, haul, species_name, common_name, species_code, length, sex) %>%
  dplyr::mutate(issue = "length")


# weight outliers
catch_stats <- new_catch %>%
  dplyr::right_join(new_haul) %>%
  dplyr::bind_rows(old_catch) %>%
  dplyr::group_by(species_code) %>%
  dplyr::add_count() %>%
  dplyr::filter(n > 20 | is.na(n)) %>% # filtering out species we don't have enough data on
  dplyr::mutate(outlier = abs(avg_specimen_weight - median(avg_specimen_weight, na.rm = T)) > (5 * mad(avg_specimen_weight, na.rm = T)) & year == this_year) %>%
  dplyr::left_join(species_codes, by = join_by(species_code))

catch_outliers <- catch_stats %>%
  dplyr::filter(outlier) %>%
  dplyr::select(
    cruise, region, vessel = vessel_id, haul, species_name, common_name, species_code,
    weight = avg_specimen_weight, number_fish
  ) %>%
  dplyr::mutate(issue = "weight")



# length-weight outliers (specimen only)
specimen_stats <- new_lengths %>%
  dplyr::right_join(new_haul) %>%
  dplyr::bind_rows(old_lengths) %>%
  dplyr::filter(!is.na(weight) & !is.na(length)) %>%
  dplyr::group_by(species_code) %>%
  dplyr::add_count() %>%
  dplyr::filter(n > 10) %>% # filtering out species we don't have enough data on
  tidyr::nest() %>%
  dplyr::mutate(res = purrr::map(data, gam_outliers)) %>%
  tidyr::unnest(cols = c(data, res)) %>%
  dplyr::mutate(outlier = res > quantile(res, probs = .99)*1.8 & year == this_year) %>%
  dplyr::left_join(species_codes, by = join_by(species_code))


specimen_outliers <- specimen_stats %>%
  dplyr::filter(outlier) %>%
  dplyr::select(
    cruise, region, vessel=vessel_id, haul, species_name,
    common_name, species_code, length, weight, sex
  ) %>%
  dplyr::mutate(issue = "length-weight")



## Plot --------------------------------------------------
pg <- ceiling(length(unique(length_outliers$species_code)) / 16)
pdf(paste0("output/length_outliers_", this_year, ".pdf"), width = 10, height = 10)
for (i in 1:pg) {
  length_plot <- length_stats %>%
    dplyr::filter(year != this_year & species_code %in% length_outliers$species_code) %>%
    ggplot2::ggplot(aes(x = length)) +
    ggplot2::geom_density(linewidth = 0.7, col = "grey40", fill = "grey70", alpha = 0.6) +
    ggforce::facet_wrap_paginate(~species_name, scales = "free", ncol = 4, nrow = 4, page = i) +
    ggplot2::theme_classic() +
    ggplot2::theme(strip.background = element_blank()) +
    ggplot2::geom_vline(
      data = length_outliers, aes(xintercept = length),
      col = "salmon", linewidth = 0.7
    )
  print(length_plot)
}
dev.off()



pg <- ceiling(length(unique(catch_outliers$species_code)) / 16)
pdf(paste0("output/weight_outliers_", this_year, ".pdf"), width = 10, height = 10)
for (i in 1:pg) {
  weight_plot <- catch_stats %>%
    dplyr::filter(year != this_year & species_code %in% catch_outliers$species_code) %>%
    ggplot2::ggplot(aes(x = avg_specimen_weight)) +
    ggplot2::geom_density(linewidth = 0.7, col = "grey40", fill = "grey70", alpha = 0.6) +
    ggforce::facet_wrap_paginate(~species_name, scales = "free", ncol = 4, nrow = 4, page = i) +
    ggplot2::theme_classic() +
    ggplot2::theme(strip.background = element_blank()) +
    ggplot2::geom_vline(
      data = catch_outliers, aes(xintercept = weight),
      col = "salmon", linewidth = 0.7
    )
  print(weight_plot)
}
dev.off()



pdf(paste0("output/specimen_outliers_", this_year, ".pdf"), width = 10, height = 10)
specimen_plot <- specimen_stats %>%
  dplyr::filter(year != this_year & species_code %in% specimen_outliers$species_code) %>%
  ggplot2::ggplot(aes(x = length, y = weight)) +
  ggplot2::facet_wrap(~species_name, scales = "free") +
#  ggforce::facet_wrap_paginate(~species_name, scales = "free", ncol = 3, nrow = 3, page = 1) +
  ggplot2::geom_point(alpha = 0.4, col = "grey80") +
  ggplot2::geom_smooth(method = "gam", col = "black", se = FALSE, lwd = 1) +
  ggplot2::theme_classic() +
  ggplot2::theme(strip.background = element_blank()) +
  ggplot2::geom_point(
    data = specimen_outliers, aes(x = length, y = weight),
    col = "salmon"
  )
print(specimen_plot)
dev.off()
