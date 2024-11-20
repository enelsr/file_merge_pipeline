pipeline to merge a file from a commercial dna test (e.g 23andme) with the AADR 1240K or HO dataset.

the pipeline is using the following tools:

- **plink**: [plink-ng](https://github.com/chrchang/plink-ng)
- **terraseq**: [terraseq](https://github.com/enelsr/terraseq)

usage:

- clone this repository
- put your dna file in the /dna_file directory.
- `chmod +x pipeline.sh`
- `./pipeline.sh`

references

1. Mallick, S., & Reich, D. (2023). The Allen Ancient DNA Resource (AADR): A curated compendium of ancient human genomes, v62.0, September 16, 2024. Harvard Dataverse. [https://doi.org/10.7910/DVN/FFIDCW](https://doi.org/10.7910/DVN/FFIDCW)

2. Mallick, S., Micco, A., Mah, M., Ringbauer, H., Lazaridis, I., Olalde, I., Patterson, N., & Reich, D. (2024). The Allen Ancient DNA Resource (AADR) a curated compendium of ancient human genomes. In *Scientific Data* (Vol. 11, Issue 1). Springer Science and Business Media LLC. [https://doi.org/10.1038/s41597-024-03031-7](https://doi.org/10.1038/s41597-024-03031-7)
