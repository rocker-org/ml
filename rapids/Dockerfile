FROM nvcr.io/nvidia/rapidsai/notebooks:25.02-cuda12.0-py3.12
RUN mamba install -c conda-forge --yes jupyterhub notebook

#USER root
#RUN chown rapids:users /home/rapids/entrypoint.sh && chmod a+x /home/rapids/entrypoint.sh
#USER rapids

ENV PYTHONHOME=""
ENTRYPOINT []
CMD ["jupyter", "lab", "--ip", "0.0.0.0"]

