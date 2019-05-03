all:
	make cuda-base
	make cuda-dev
	make tensorflow-gpu
	make ml-gpu
	make cpu

cuda-base: cuda/base/Dockerfile
	docker build -t rocker/cuda:3.6.0 cuda/base
cuda-devel: cuda/devel/Dockerfile
	docker build -t rocker/cuda-dev:3.6.0 cuda/devel

tensorflow-gpu: tensorflow/gpu/Dockerfile
	docker build -t rocker/tensorflow-gpu:3.6.0 tensorflow/gpu

ml-gpu: ml/gpu/Dockerfile
	docker build -t rocker/ml-gpu:3.6.0 ml/gpu

cpu: tensorflow/cpu/Dockerfile ml/cpu/Dockerfile
	docker build -t rocker/tensorflow:3.6.0 tensorflow/cpu
	docker build -t rocker/ml:3.6.0 ml/cpu

