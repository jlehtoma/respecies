context("Package utility functions")

test_that("Country codes are handled correctly", {  
  # China, country code should work as a string and numeric
  expect_identical(resolve_country(country="156"), 156,
               "Contry code as character is not resolved correctly to code")
  expect_identical(resolve_country(country=156), 156,
               "Contry code as numeric is not resolved correctly to code")
  expect_identical(resolve_country(country="Finland"), 246,
               "Contry name is not resolved correctly to code")
  
  # Using full names
  expect_identical(resolve_country(country="156", full.name=TRUE), "China",
                   "Contry code as character is not resolved correctly to full name")
  expect_identical(resolve_country(country=156, full.name=TRUE), "China",
                   "Contry code as numeric is not resolved correctly to full name")
  expect_identical(resolve_country(country="Finland", full.name=TRUE), "Finland",
                   "Contry name is not resolved correctly to full name")
})

test_that("Non-existing country names and codes raise an error", {
  expect_error(resolve_country(country="99999"),
               info="Non-existant country code should raise an error")
  expect_error(resolve_country(country=99999),
               info="Non-existant country code should raise an error")
  expect_error(resolve_country(country="FooBaristan"),
               info="Non-existant country name should raise an error")
})

test_that("Check that the conservation status codes are handled correctly", {
  expect_equal(check_iucn_status("CR"), "CR", 
              "Valid IUCN status code CR causes problems.")
  all_codes <- c("CR", "EN", "VU", "NT", "LC", "EX", "EW", "DD")
  expect_equal(check_iucn_status(all_codes), all_codes, 
              "Using all valid IUCN status codes causes problems")
  suppressWarnings(expect_warning(check_iucn_status(c("CR", "EN", "VU", "Foo", 
                                                      "LC", "EX", "EW", "DD")),
                   info="Invalid item should cause an error"))
  suppressWarnings(expect_equal(check_iucn_status(c("CR", "EN", "VU", "Foo", 
                                                    "LC", "EX", "EW", "DD")), 
                                                  c("CR", "EN", "VU", 
                                                    "LC", "EX", "EW", "DD"),
                            "Invalid item is not removed from the vector"))
  suppressWarnings(expect_error(check_iucn_status("Foo"),
               info="All IUCN status codes being incorrect should cause an error"))
  suppressWarnings(expect_error(check_iucn_status(c("Foo", "Bar")),
               info="All IUCN status codes being incorrect should cause an error"))
})

test_that("DOPA responses are parsed correctly", {
  
  # Create some test data to mock the DOPA response object structure
  x <- list(list("ID"=1, "var1"="B", "var2"="D"),
            list("ID"=2, "var1"="F", "var2"="H"),
            list("ID"=3, "var1"="I", "var2"=NULL))
  
  # Helper function to check if a list of lists has NULL-elements
  has.nulls <- function(x) {
    return(any(unlist(lapply(x, function(x) lapply(x, is.null)))))
  }
  
  expect_is(parse_dopa_response(x), "data.frame",
            "Parsing DOPA response should return a dataframe")
  expect_false(has.nulls(parse_dopa_response(x)),
               "Parsed DOPA response should not have NULL elements")
  
})

test_that("Data frame with WKT is converted correctly", {
  
  suppressMessages(library(rgeos))
  suppressMessages(library(sp))
  
  # Create some test data
  x <- data.frame("ID"=c(1, 2, 3), "var1"=c("A", "B", "C"), 
                  "WKT"=c("MULTIPOLYGON(((1.0 2.0, 1.0 3.0, 2.0 3.0, 1.0 2.0)))",
                          "MULTIPOLYGON(((3.0 4.0, 3.0 5.0, 4.0 5.0, 3.0 4.0)))",
                          "MULTIPOLYGON(((11.0 12.0, 11.0 13.0, 12.0 13.0, 11.0 12.0)))"),
                  stringsAsFactors=FALSE)
  
  # Erraneous column name for the WKT field
  expect_error(sp_x <- wktdf2sp(x, wkt.col="WKTXX"),
               info="Missing column name should give an error")
  
  sp_x <- wktdf2sp(x, wkt.col="WKT")
  
  expect_is(sp_x, "SpatialPolygonsDataFrame",
            info="Returned object is not SpatialPolygonsDataFrame")
  
  # Check all 3 rows
  for (i in 1:nrow(x)) {
    expect_true(gEqualsExact(readWKT(text = x[i,]$WKT, p4s="+init=epsg:4326"), 
                             sp_x[i,]),
                info="Geometries are not the same")
  }
  
})

