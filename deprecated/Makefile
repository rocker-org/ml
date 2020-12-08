all:
	make gpu
	make cpu

gpu:
	make cuda-base
	make cuda-devel
	make tensorflow-gpu
	make ml-gpu

cpu:
	make tensorflow
	make ml

cuda-base: cuda/base/Dockerfile
	docker build -t rocker/cuda:3.6.0 cuda/base

cuda-devel: cuda/devel/Dockerfile
	docker build -t rocker/cuda-dev:3.6.0 cuda/devel

tensorflow-gpu: tensorflow/gpu/Dockerfile
	docker build -t rocker/tensorflow-gpu:3.6.0 tensorflow/gpu

ml-gpu: ml/gpu/Dockerfile
	docker build -t rocker/ml-gpu:3.6.0 ml/gpu

tensorflow: tensorflow/cpu/Dockerfile 
	docker build -t rocker/tensorflow:3.6.0 tensorflow/cpu

ml: ml/cpu/Dockerfile
	docker build -t rocker/ml:3.6.0 ml/cpu

