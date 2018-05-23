follows the exercises from the textbook Terraform Up & Running

to create graph .dot file:
	$ terraform graph > graph.dot
To convert it to a png
	$ homebrew install graphviz
	$ dot -Tpng graph.dot -o graph.png
