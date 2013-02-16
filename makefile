engine.so: setup.py engine.pyx
	python setup.py build_ext --inplace
