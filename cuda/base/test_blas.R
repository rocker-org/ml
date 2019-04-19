
N <- 2^13
system.time(
  replicate(10,{
  matrix(rnorm(N*N), nrow=N, ncol=N) %*% 
  matrix(rnorm(N*N), nrow=N, ncol=N)})
  )


N <- 2^14
system.time(
    matrix(rnorm(N*N), nrow=N, ncol=N) %*% 
      matrix(rnorm(N*N), nrow=N, ncol=N)
)
N <- 2^12
system.time({
  M <- matrix(rnorm(N*N), nrow=N, ncol=N)
 replicate(10, det(M))
})
