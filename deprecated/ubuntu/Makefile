all:
	make cuda-9.0
	make cuda-10.0
	make tensorflow-2.0

cuda-10.0: 10.0/Dockerfile
	docker build -t rocker/ml:cuda-10.0 -f 10.0/Dockerfile .
cuda-9.0: 9.0/Dockerfile
	docker build -t rocker/ml:cuda-9.0 -f 9.0/Dockerfile .

tensorflow-2.0: tensorflow/Dockerfile
	docker build -t rocker/ml:cuda-10.0-tf-2.0 -f tensorflow/Dockerfile .
