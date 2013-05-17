StructConnRepro
===============

Neuroinformatics Technical Report: Reproducibility of graph metrics of human brain structural networks
Jeffrey Duda, Phil Cook, James Gee

Submitted Abstract/Proposal
Recent interest in the human connectome has led to the application of graph theoretical analysis to human brain structural networks, in particular white matter connectivity inferred from diffusion imaging and fiber tractography. While these methods have been used to study a variety of patient populations, there has been less examination of the reproducibility of these methods. These graph metrics typically derive from fiber tractography, however a number of tractography algorithms exist and many of these are known to be sensitive to user-selected parameters. We shall examine how these algorithm and parameter choices influence the reproducibility of proposed graph metrics. A freely available data set, the Multi-Modal MRI Reproducibility Resource, will serve as the basis for this study. ANTs, based upon ITKv4, will be used for the registration and segmentation steps needed to align and label individual brains. Camino, an open-source toolkit, will be used for: DT reconstruction, fiber tracking, and the generation of structural connectivity matrices. An ITK module will be created to implement the graph analysis metrics. 
