FROM nvcr.io/nvidia/rapidsai/notebooks:25.02-cuda12.0-py3.12
RUN mamba --channel conda-forge --yes install jupyterhub notebook

CMD ["jupyter", "lab", "--ip", "0.0.0.0"]

