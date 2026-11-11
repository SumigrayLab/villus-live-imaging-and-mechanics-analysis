# Villus Live Imaging and Mechanics Analysis

This repository contains custom MATLAB scripts used for quantitative analysis of intestinal epithelial dynamics and tissue mechanics in the study:

**“Tissue geometry encodes a surface tension gradient that drives epithelial renewal.”**

The scripts include image registration, processing of manually tracked cell trajectories, strain-rate and motion-coherence analysis, nuclear strain-gradient calculation, and hierarchical mixed-effects statistical analysis.

## Requirements

- MATLAB
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox

Some scripts may require additional MATLAB toolboxes depending on the functions used.

## Scripts

### `Image_Registration.m`

Corrects global drift in time-lapse image sequences prior to quantitative analysis.

The registration workflow includes:
- rigid translational alignment between frames;
- normalized cross-correlation for estimation of translational offsets;
- refinement of residual subpixel drift using optical-flow-based motion estimation;
- cubic interpolation for generation of registered image stacks.

The procedure is designed to remove global tissue drift while preserving relative cellular motion.

---

### `Cell_Tracking.m`

Processes epithelial cell trajectories that were manually generated using the MTrackJ plugin in Fiji/ImageJ.

The script does not perform automated cell tracking. Instead, it imports and analyzes exported trajectory coordinates to calculate cell displacement and velocity and to organize measurements according to spatial position along the villus axis.

---

### `Strain_rate_motion_coherence.m`

Calculates tissue strain rate and motion coherence from spatially resolved velocity measurements.

The script was used for analysis of collective epithelial motion, including experiments involving local photo-inactivation of blebbistatin.

Outputs include:
- local strain rate;
- signed axial strain rate where applicable;
- motion coherence;
- spatially binned measurements along defined regions of interest.

---

### `Strain_gradient.m`

Calculates the spatial gradient of nuclear shape strain along the villus axis.

Nuclear shape strain is quantified from nuclear shape anisotropy and evaluated as a function of curvature length from the villus tip. The script calculates spatial strain gradients over defined distance intervals for comparison between experimental conditions.

---

### `Mixed_model_analysis_Strain.m`

Performs hierarchical mixed-effects analysis of spatial nuclear strain profiles.

The analysis includes:
- treatment and curvature length as fixed effects;
- treatment × curvature length interaction;
- mouse as a random effect;
- villus nested within mouse as a random effect.

The input table should contain the following variables:

```text
Mouse
Villus
Treatment
Curvature_length
Nuclear_strain
```

The model accounts for repeated spatial measurements within villi and biological variability between mice.

---

### `Mixed_model_analysis_Strain_gradient.m`

Performs hierarchical mixed-effects analysis of spatial strain-gradient profiles.

For analyses of the near-tip strain gradient, measurements within the first 150 µm from the villus tip are included.

The analysis includes:
- treatment and curvature length as fixed effects;
- treatment × curvature length interaction;
- mouse as a random effect;
- villus nested within mouse as a random effect.

The input table should contain the following variables:

```text
Mouse
Villus
Treatment
Curvature_length
Strain_gradient
```

Statistical significance is evaluated using Satterthwaite approximation for degrees of freedom.

## General workflow

A typical analysis proceeds as follows:

1. Register time-lapse images using `Image_Registration.m`.
2. Manually track epithelial cells in MTrackJ and export trajectory coordinates.
3. Process exported trajectories using `Cell_Tracking.m`.
4. Calculate strain rate and motion coherence using `Strain_rate_motion_coherence.m`.
5. Calculate nuclear strain gradients using `Strain_gradient.m`.
6. Analyze spatial nuclear strain profiles using `Mixed_model_analysis_Strain.m`.
7. Analyze spatial strain-gradient profiles using `Mixed_model_analysis_Strain_gradient.m`.

## Data organization

Experimental datasets should retain identifiers for both biological replicate and individual villus. Mouse and villus identifiers should be unique across treatment groups to ensure correct specification of the hierarchical structure.

Users should update input file names and directory paths within individual scripts as needed.

## Code availability

These scripts are provided to support reproducibility of the custom quantitative analyses used in the associated study. Routine statistical analyses performed using standard commercial software and standard image-analysis workflows are not included in this repository.

## Contact

For questions regarding the analysis, please contact the corresponding authors of the associated manuscript.
