% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/db.R
\name{db_sql}
\alias{db_sql}
\title{A Wrapper function for DBI interface}
\usage{
db_sql(sql, method, con = NULL)
}
\arguments{
\item{sql}{multile sql statements}

\item{method}{method of DBI}

\item{con}{a connection}
}
\value{
Results of last sql statement with method for DBI interface
}
\description{
A Wrapper function for DBI interface
}
