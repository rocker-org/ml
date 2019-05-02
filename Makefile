all:
	make cuda-img
	make tensorflow-img
	make ml-img

cuda-img: cuda/base/Dockerfile cuda/devel/Dockerfile
	docker build -t rocker/cuda:3.6.0 cuda/base
	docker build -t rocker/cuda-dev:3.6.0 cuda/devel

tensorflow-img: tensorflow/gpu/Dockerfile
	docker build -t rocker/tensorflow-gpu:3.6.0 tensorflow/gpu

ml-img: ml/gpu/Dockerfile
	docker build -t rocker/ml-gpu:3.6.0 ml/gpu

cpu: tensorflow/cpu/Dockerfile ml/cpu/Dockerfile
	docker build -t rocker/tensorflow:3.6.0 tensorflow/cpu
	docker build -t rocker/ml:3.6.0 ml/cpu

