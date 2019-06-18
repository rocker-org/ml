all:
	make cuda-9.0
	make cuda-10.0

cuda-10.0: 10.0/Dockerfile
	docker build -t rocker/cuda-10.0 10.0
cuda-9.0: 9.0/Dockerfile
	docker build -t rocker/cuda-9.0 9.0


