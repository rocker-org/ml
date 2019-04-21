all:
	make cuda-img 
	make tensorflow-img
	make ml-img

cuda-img: cuda/base/Dockerfile cuda/devel/Dockerfile 
	docker build -t rocker/cuda:3.5.3 cuda/base
	docker build -t rocker/cuda-dev:3.5.3 cuda/devel

tensorflow-img: tensorflow/gpu/Dockerfile
	docker build -t rocker/tensorflow-gpu:3.5.3 tensorflow/gpu

ml-img: ml/gpu/Dockerfile
	docker build -t rocker/ml-gpu:3.5.3 ml/gpu

cpu: tensorflow/cpu/Dockerfile ml/cpu/Dockerfile
	docker build -t rocker/tensorflow:3.5.3 tensorflow/cpu
	docker build -t rocker/ml:3.5.3 ml/cpu

