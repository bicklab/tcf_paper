version 1.0


workflow Tca_Analysis {
    input {
        File cram_file
        File crai_file
        String sample_id
        File tca_rscript
        Int memory_gb
        Int disk_size
        Int cpu
    }


    call get_tca_coverage{
        input:
            cram_file = cram_file,
            crai_file = crai_file,
            sample_id = sample_id,
            memory_gb = memory_gb,
            disk_size = disk_size,
            cpu = cpu
    }

    call run_tcellextrect {
        input:
            coverage_file = get_tca_coverage.coverage_over_tca,
            tca_rscript = tca_rscript,
            memory_gb = memory_gb,
            disk_size = disk_size,
            cpu = 1
    }

    output {
        File covereage_file = get_tca_coverage.coverage_over_tca
        File tcell_fraction_file = run_tcellextrect.tcell_fraction
    }
}


task get_tca_coverage {
    input {
        File cram_file
        File crai_file
        String sample_id
        Int memory_gb
        Int disk_size
        Int cpu
    }
    String chrom = "chr14"
    Int start = 21621904
    Int stop = 22552132

    command {
        set -euo pipefail
        echo $(date +"[%b %d %H:%M:%S] samtools: getting coverage over chr14")

        samtools depth -a -r ${chrom}:${start}-${stop} ${cram_file} > ${sample_id}_tca_depth.csv
        echo $(date +"[%b %d %H:%M:%S] done.")
    }

    output {
        File coverage_over_tca = sample_id + "_tca_depth.csv"
    }

    runtime {
    	docker: 
        memory: memory_gb + "GB"
        disks: "local-disk " + disk_size + " HDD"
		cpu: cpu
        preemptible: 1
        maxRetries: 0
    }

    meta {
        author: "Original: Aine Fairbrother-Browne, Modified: Hannah Poisner"
        email: "hannah.m.poisner@vanderbilt.edu"
        modifications: "rewrote for specific gene coverage instead of chrM"
    }
}

task run_tcellextrect {
    input {
        File coverage_file
        File tca_rscript
        String sample_id
        Int memory_gb
        Int disk_size
        Int cpu
    }


    command {
        set -euo pipefail

        ## tca_rscript takes the coverage file and runs the runTcellExTRECT function
        R < ~{tca_rscript} --vanilla --args ${coverage_file} ${sample_id}_tcell_fraction.txt
    }

    output {
        File tcell_fraction = sample_id + "_tcell_fraction.txt"
    }

    runtime {
    	docker: 
        memory: memory_gb + "GB"
        disks: "local-disk " + disk_size + " HDD"
		cpu: cpu
        preemptible: 1
        maxRetries: 0
    }

    meta {
        author: "Hannah Poisner "
        email: "hannah.m.poisner@vanderbilt.edu"
    }
}