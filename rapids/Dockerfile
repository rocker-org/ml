FROM nvcr.io/nvidia/rapidsai/notebooks:25.02-cuda12.0-py3.12
ENV PYTHONIOENCODING=utf-8
ENV LC_ALL=en_US.UTF-8

RUN mamba install -c conda-forge --yes jupyterhub notebook

#USER root
#RUN chown rapids:users /home/rapids/entrypoint.sh && chmod a+x /home/rapids/entrypoint.sh
#USER rapids

USER root
RUN locale-gen en_US.UTF-8
USER rapids

ENTRYPOINT []
CMD ["jupyter", "lab", "--ip", "0.0.0.0"]

