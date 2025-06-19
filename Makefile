
.PHONY: install-nkp-kubeflow
install-nkp-kubeflow:
	$(info Installing kubeflow on NKP...)
	cd kubeflow; ./install.sh

.PHONY: install-vanilla-kubeflow
install-vanilla-kubeflow:
	$(info Installing vanilla kubeflow...)
	cd kubeflow; ./install.sh -v