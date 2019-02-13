all:
	make cuda-img 
	make tf-img
	make ml-img

cuda-img: cuda/9.0/base/Dockerfile cuda/10.0/base/Dockerfile cuda/9.0/devel/Dockerfile cuda/10.0/devel/Dockerfile
	docker build -t rocker/cuda:9.0-base cuda/9.0/base
	docker build -t rocker/cuda:9.0-devel cuda/9.0/devel
	docker build -t rocker/cuda:10.0-base cuda/10.0/base
	docker build -t rocker/cuda:10.0-devel cuda/10.0/devel

tf-img: tf/cpu/Dockerfile tf/gpu/Dockerfile
	docker build -t rocker/tf:cpu tf/cpu
	docker build -t rocker/tf:gpu tf/gpu

ml-img: ml/gpu/Dockerfile ml/cpu/Dockerfile
	docker build -t rocker/ml:cpu
	docker build -t rocker/ml:gpu


