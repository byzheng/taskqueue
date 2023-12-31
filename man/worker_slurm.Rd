% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/worker.R
\name{worker_slurm}
\alias{worker_slurm}
\title{Create a worker on slurm cluster}
\usage{
worker_slurm(project, resource, rcode, modules = NULL)
}
\arguments{
\item{project}{Project name}

\item{resource}{Resource name}

\item{rcode}{rscript file path}

\item{modules}{extra modules to load in slurm}
}
\value{
no return
}
\description{
Create a worker on slurm cluster
}
