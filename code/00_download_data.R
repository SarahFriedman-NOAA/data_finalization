## Download data sets to local machine -------------------------------------------------------
if (exists("channel")) {
  # RACEBASE tables to query
  locations <- c(
    "RACE_DATA.V_CRUISES",
    "RACE_DATA.RACE_SPECIES_CODES",

    # biological edit data
    "RACE_DATA.EDIT_CATCH_SPECIES",
    "RACE_DATA.EDIT_CATCH_SAMPLES",
    "RACE_DATA.EDIT_LENGTHS",
    "RACE_DATA.EDIT_SPECIMENS",

    # effort edit data
    "RACE_DATA.EDIT_HAULS",
    "RACE_DATA.EDIT_EVENTS",
    "RACE_DATA.EDIT_HAUL_MEASUREMENTS",
    #    "RACE_DATA.V_EXTRACT_FINAL_LENGTHS",

    # historical data
    "RACEBASE.CATCH",
    "RACEBASE.LENGTH",
    "RACEBASE.HAUL",
    "RACEBASE.SPECIMEN",
    "RACEBASE.CRUISE",
    "RACEBASE.CATCH"
  )

  if (!file.exists("data/oracle")) dir.create("data/oracle", recursive = TRUE)


  # downloads tables in "locations"
  for (i in 1:length(locations)) {
    print(locations[i])
    filename <- tolower(gsub("\\.", "-", locations[i]))
    a <- RODBC::sqlQuery(channel, paste0("SELECT * FROM ", locations[i]))
    readr::write_csv(
      x = a,
      here::here("data", "oracle", paste0(filename, ".csv"))
    )
    remove(a)
  }
} else {
  # reads downloaded tables into R environment
  aa <- list.files(
    path = here::here("data", "oracle"),
    pattern = "\\.csv"
  )
  if (!all(aa %in% tolower(gsub("\\.", "-", locations)))) {
    cat("Not connected to Oracle database and can not locate proper tables in cache.
        Connect to Oracle and re-run script to proceed.\n")
    gapindex::get_connected()
  } else {
    cat("Not connected to Oracle database. Will use cached tables.\n")
  }
}
