all:
	make cuda-img 
	make tf-img
	make ml-img

cuda-img: cuda/base/Dockerfile cuda/devel/Dockerfile 
	docker build -t rocker/cuda:3.5.2 cuda/base
	docker build -t rocker/cuda-dev:3.5.2 cuda/devel

tf-img: tf/cpu/Dockerfile tf/gpu/Dockerfile
	docker build -t rocker/tf:3.5.2 tf/cpu
	docker build -t rocker/tf-gpu:3.5.2 tf/gpu

ml-img: ml/gpu/Dockerfile ml/cpu/Dockerfile
	docker build -t rocker/ml:3.5.2 ml/cpu
	docker build -t rocker/ml-gpu:3.5.2 ml/gpu


