library(dplyr)
library(tidyverse)
library(psych)
library(corrplot)
library(lme4)

# get H betas
setwd('~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/MMClock_aroma_preconvolve_fse_groupfixed/sceptic-clock-feedback-v_entropy-preconvolve_fse_groupfixed/v_entropy/')
meta <- read_csv("~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/MMClock_aroma_preconvolve_fse_groupfixed/sceptic-clock-feedback-v_entropy-preconvolve_fse_groupfixed/v_entropy/v_entropy_cluster_metadata.csv")
meta$label <- substr(meta$label,22,100)
meta_overall <- meta[meta$l2_contrast == 'overall' & meta$l3_contrast == 'Intercept' & meta$model == 'Intercept-Age',]
Hbetas <- read_csv("v_entropy_roi_betas.csv")
h <- as.tibble(Hbetas[Hbetas$l2_contrast == 'overall' & Hbetas$l3_contrast == 'Intercept' & Hbetas$model == 'Intercept-Age',1:3]) %>% filter(cluster_number<11)
# head(merge(h,meta))
rois <- distinct(meta_overall[,c(5,12)])

# inspect distributions
hrois <- inner_join(h,meta_overall)
hrois$labeled_cluster <- paste(hrois$cluster_number,hrois$label)
ggplot(hrois,aes(scale(cope_value))) + geom_histogram() + facet_wrap(~label)
h_wide <- spread(h,cluster_number,cope_value)
# head(h_wide)
# with group-fixed parameters we don't seem to need the winsorization step!!!
# h_wide <- h_wide %>% mutate_if(is.double, winsor,trim = .075)

just_rois <- h_wide[,2:11]
# winsorize to deal with beta ouliers

# non-parametric correlations to deal with outliers
clust_cor <- cor(just_rois,method = 'pearson')
# parametric correlations on winsorised betas
# clust_cor <- cor(just_rois_w,method = 'pearson')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("h_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(clust_cor, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = 1-clust_cor, sig.level=0.75, insig = "blank")
dev.off()
mh <- nfactors(clust_cor, n=5, rotate = "oblimin", diagonal = FALSE,fm = "pa", n.obs = 70, SMC = FALSE)
h.fa = psych::fa(just_rois, nfactors=2, rotate = "oblimin", fm = "pa")
fscores <- factor.scores(just_rois, h.fa)$scores
h_wide$h_f1_fp <- fscores[,1]
h_wide$h_f2_neg_paralimb <- fscores[,2]
h_wide$h_HippAntL <- h_wide$`9`
h_wide$h_vmPFC <- h_wide$`6`

# add value betas -- use v_max as theoretically interesting and unbiased by choice
setwd('~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/MMClock_aroma_preconvolve_fse_groupfixed/sceptic-clock-feedback-v_max-preconvolve_fse_groupfixed/v_max/')
vmeta <- read_csv("v_max_cluster_metadata.csv")
vmeta$label <- substr(vmeta$label,21,100)
vmeta_overall <- vmeta[vmeta$l2_contrast == 'overall' & vmeta$l3_contrast == 'Intercept' & vmeta$model == 'Intercept-Age',]
vbetas <- read_csv("v_max_roi_betas.csv")
v <- as.tibble(vbetas[vbetas$l2_contrast == 'overall' & vbetas$l3_contrast == 'Intercept' & vbetas$model == 'Intercept-Age',1:3]) %>% filter(cluster_number<15)
vrois_list <- distinct(vmeta_overall[,c(5,12)])

vrois <- inner_join(v,vmeta_overall)
vrois$labeled_cluster <- paste(vrois$cluster_number,vrois$label)
vmeta_overall$labeled_cluster <- paste(vmeta_overall$cluster_number,vmeta_overall$label)

v_labeled <- inner_join(v,vrois_list)
v_labeled$labeled_cluster <- paste(v_labeled$cluster_number,v_labeled$label)
v_labeled <- select(v_labeled,c(1,3,5))



# inspect distributions
vrois <- inner_join(v_labeled,vmeta_overall)
ggplot(vrois,aes(scale(cope_value))) + geom_histogram() + facet_wrap(~labeled_cluster)
v_wide <- spread(v_labeled,labeled_cluster,cope_value)
# try v winsorization given the left outliers
# v_wide <- v_wide %>% mutate_if(is.double, winsor,trim = .075)

# few outliers, let's hold off on winsorizing for now
# h_wide <- h_wide %>% mutate_if(is.double, winsor,trim = .075)

# I am worried about these scores: a lot of the V+ f2 variance comes from fusiform gyri (4,11)
# let's redo using only fronto-striatal clusters (vmPFC - 10, BG - 2, vlPFC - 9,14) removing fusiform (4,11)
# and cerebellar (8) clusters
v_wide <- subset(v_wide, select = -c(`11  Right Inferior Temporal Gyrus`, `4  Left Inferior Temporal Gyrus` ,`8  Right Cerebellum (Crus 2)`))
v_wide <- v_wide %>% mutate_if(is.double, winsor,trim = .075)


vjust_rois <- v_wide[,2:ncol(v_wide)]
# winsorize to deal with beta ouliers

# non-parametric correlations to deal with outliers
# parametric correlations on winsorised betas
vclust_cor <- cor(vjust_rois,method = 'pearson')

mv <- nfactors(vclust_cor, n=5, rotate = "oblimin", diagonal = FALSE,fm = "pa", n.obs = 70, SMC = FALSE)
v.fa = psych::fa(vjust_rois, nfactors=2, rotate = "oblimin", fm = "pa")
vfscores <- factor.scores(vjust_rois, v.fa)$scores
v_wide$v_f1_neg_cog <- vfscores[,1]
v_wide$v_f2_paralimb <- vfscores[,2]

vclust_cor <- corr.test(v_wide %>% select_if(is.double),method = 'pearson', adjust = 'none')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("v_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(vclust_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = vclust_cor$p, sig.level=0.05, insig = "blank")
dev.off()

# a bit crazy, but let's put v and h into a single factor analysis
vh_wide <- inner_join(subset(v_wide, select = c("feat_input_id","v_f1_neg_cog","v_f2_paralimb")),
                      subset(h_wide, select = c("feat_input_id","h_f1_fp","h_f2_neg_paralimb", "h_HippAntL")), by = "feat_input_id")
vhjust_rois <- vh_wide %>% select_if(is.double)
vhclust_cor <- corr.test(vhjust_rois,method = 'pearson', adjust = 'none')
pdf("vh_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(vhclust_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = vhclust_cor$p, sig.level=0.05, insig = "blank")
dev.off()
# the first value (V+) factor is correlated with the entropy hippocampal factor (.55)

# OK, that went well -- let's add dAUC
setwd('~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/MMClock_aroma_preconvolve_fse_groupfixed/sceptic-clock-feedback-d_auc-preconvolve_fse_groupfixed/d_auc/')
dmeta <- read_csv("d_auc_cluster_metadata.csv")
dmeta$label <- substr(dmeta$label,14,100)
dmeta_overall <- dmeta[dmeta$l2_contrast == 'overall' & dmeta$l3_contrast == 'Intercept' & dmeta$model == 'Intercept-Age',]
dbetas <- read_csv("d_auc_roi_betas.csv")
d <- as.tibble(dbetas[dbetas$l2_contrast == 'overall' & dbetas$l3_contrast == 'Intercept' & dbetas$model == 'Intercept-Age',1:3]) %>% filter(cluster_number<15)
# head(merge(h,meta))
drois_list <- distinct(dmeta_overall[,c(5,12)])

# inspect distributions
# for some reason, the clusters do not seem to fit the map -- check with MNH (big clusters broken down?) !!
drois <- inner_join(d,dmeta_overall)
drois$labeled_cluster <- paste(drois$cluster_number,drois$label)
ggplot(drois,aes(scale(cope_value))) + geom_histogram() + facet_wrap(~labeled_cluster)
d_wide <- spread(d,cluster_number,cope_value)

# few outliers, let's hold off on winsorizing for now
# h_wide <- h_wide %>% mutate_if(is.double, winsor,trim = .075)

djust_rois <- d_wide[,2:ncol(d_wide)]
# winsorize to deal with beta ouliers

# non-parametric correlations to deal with outliers
dclust_cor <- cor(djust_rois,method = 'pearson')
# parametric correlations on winsorised betas
# clust_cor <- cor(just_rois_w,method = 'pearson')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("d_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(dclust_cor, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = 1-dclust_cor, sig.level=0.75, insig = "blank")
dev.off()
# looks like a single dimension


d.fa = psych::fa(djust_rois, nfactors=3)
dfscores <- factor.scores(djust_rois, d.fa)$scores
d_wide$d_f1_FP_SMA <- dfscores[,1]
d_wide$d_f2_VS <- dfscores[,2]
d_wide$d_f3_ACC_ins <- dfscores[,3]

# a bit crazy, but let's put v and h into a single factor analysis
dvh_wide <- inner_join(vh_wide,d_wide[,c("feat_input_id","d_f1_FP_SMA","d_f2_VS", "d_f3_ACC_ins")], by = "feat_input_id")
dvhjust_rois <- dvh_wide[,2:ncol(dvh_wide)]
dvhclust_cor <- corr.test(dvhjust_rois,method = 'pearson', adjust = 'none')
pdf("dvh_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(dvhclust_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = dvhclust_cor$p, sig.level=0.05, insig = "blank")
dev.off()

#####
# add KLD
setwd('~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/MMClock_aroma_preconvolve_fse_groupfixed/sceptic-clock-feedback-mean_kld-preconvolve_fse_groupfixed/mean_kld/')
kmeta <- read_csv("mean_kld_cluster_metadata.csv")
kmeta$label <- substr(kmeta$label,22,100)
kmeta_overall <- kmeta[kmeta$l2_contrast == 'overall' & kmeta$l3_contrast == 'Intercept' & kmeta$model == 'Intercept-Age',]
kbetas <- read_csv("mean_kld_roi_betas.csv")
k <- as.tibble(kbetas[kbetas$l2_contrast == 'overall' & kbetas$l3_contrast == 'Intercept' & kbetas$model == 'Intercept-Age',1:3]) %>% filter(cluster_number<10 | cluster_number == 11 | cluster_number == 14)
# head(merge(h,meta))
krois_list <- distinct(kmeta_overall[,c(5,12)])

# inspect distributions
# for some reason, the clusters do not seem to fit the map -- check with MNH (big clusters broken down?) !!
krois <- inner_join(k,kmeta_overall)
krois$labeled_cluster <- paste(krois$cluster_number,krois$label)
kmeta_overall$labeled_cluster <- paste(kmeta_overall$cluster_number,kmeta_overall$label)
ggplot(krois,aes(scale(cope_value))) + geom_histogram() + facet_wrap(~labeled_cluster)

k_labeled <- inner_join(k,krois_list)
k_labeled$labeled_cluster <- paste(k_labeled$cluster_number,k_labeled$label)
k_labeled <- select(k_labeled,c(1,3,5))

k_wide <- spread(k_labeled,labeled_cluster,cope_value)

# some outliers, let's winsorize for now
k_wide <- k_wide %>% mutate_if(is.double, winsor,trim = .075)

kjust_rois <- k_wide[,2:ncol(k_wide)]
# winsorize to deal with beta ouliers

# non-parametric correlations to deal with outliers
kclust_cor <- corr.test(kjust_rois,method = 'pearson', adjust = 'none')
# parametric correlations on winsorised betas
# clust_cor <- cor(just_rois_w,method = 'pearson')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("k_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(kclust_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = kclust_cor$p, sig.level=0.05, insig = "blank")
dev.off()
# looks like a single dimension

mk <- nfactors(kclust_cor$r, n=5, rotate = "oblimin", diagonal = FALSE,fm = "pa", n.obs = 70, SMC = FALSE)
k.fa = psych::fa(kjust_rois, nfactors=1, rotate = "oblimin", fm = "pa")

kfscores <- factor.scores(kjust_rois, k.fa)$scores
k_wide$k_f1_all_pos <- kfscores[,1]
# k_wide$k_f1_IPL_ventr_stream <- kfscores[,1]
# k_wide$k_f2_prefrontal_bg <- kfscores[,2]

dvhk_wide <- inner_join(dvh_wide,k_wide[,c("feat_input_id","k_f1_all_pos")])
### KLD at feedback
#####
# add KLD
setwd('~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/MMClock_aroma_preconvolve_fse_groupfixed/sceptic-clock-feedback-mean_kld_feedback-preconvolve_fse_groupfixed/mean_kld_feedback/')
kfmeta <- read_csv("mean_kld_feedback_cluster_metadata.csv")
kfmeta$label <- substr(kfmeta$label,22,100)
kfmeta_overall <- kfmeta[kfmeta$l2_contrast == 'overall' & kfmeta$l3_contrast == 'Intercept' & kfmeta$model == 'Intercept-Age',]
kfbetas <- read_csv("mean_kld_feedback_roi_betas.csv")
kf <- as.tibble(kfbetas[kfbetas$l2_contrast == 'overall' & kfbetas$l3_contrast == 'Intercept' & kfbetas$model == 'Intercept-Age',1:3]) %>% filter(cluster_number<23)
# head(merge(h,meta))
kfrois_list <- distinct(kfmeta_overall[,c(5,12)])

# inspect distributions
# for some reason, the clusters do not seem to fit the map -- check with MNH (big clusters broken down?) !!
kfrois <- inner_join(kf,kfmeta_overall)
kfrois$labeled_cluster <- paste(kfrois$cluster_number,kfrois$label)
kfmeta_overall$labeled_cluster <- paste(kfmeta_overall$cluster_number,kfmeta_overall$label)
ggplot(kfrois,aes(scale(cope_value))) + geom_histogram() + facet_wrap(~labeled_cluster)

kf_labeled <- inner_join(kf,kfrois_list)
kf_labeled$labeled_cluster <- paste(kf_labeled$cluster_number,kf_labeled$label)
kf_labeled <- select(kf_labeled,c(1,3,5))

kf_wide <- spread(kf_labeled,labeled_cluster,cope_value)

# some outliers, let's winsorize for now
kf_wide <- kf_wide %>% mutate_if(is.double, winsor,trim = .075)

kfjust_rois <- kf_wide[,2:ncol(kf_wide)]
# winsorize to deal with beta ouliers

# non-parametric correlations to deal with outliers
kfclust_cor <- corr.test(kfjust_rois,method = 'pearson', adjust = 'none')
# parametric correlations on winsorised betas
# clust_cor <- cor(just_rois_w,method = 'pearson')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("kf_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(kfclust_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = kfclust_cor$p, sig.level=0.05, insig = "blank")
dev.off()
# looks like a single dimension
mkf <- nfactors(kfclust_cor$r, n=5, rotate = "oblimin", diagonal = FALSE,fm = "pa", n.obs = 70, SMC = FALSE)
kf.fa = psych::fa(kfjust_rois, nfactors=2, rotate = "oblimin", fm = "pa")

kffscores <- factor.scores(kfjust_rois, kf.fa)$scores
kf_wide$kf_f1_pos <- kffscores[,1]
kf_wide$kf_f2_vmpfc_precun <- kffscores[,2]
# kf_wide$kf_f1_fp_temp <- kffscores[,1]
# kf_wide$kf_f2_vmpfc_precun <- kffscores[,2]
# kf_wide$kf_f3_str_front_ins <- kffscores[,3]

dvhkf_wide <- inner_join(dvhk_wide,kf_wide[,c("feat_input_id","kf_f1_pos", "kf_f2_vmpfc_precun")])


#####
# add PE
setwd('~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/MMClock_aroma_preconvolve_fse_groupfixed/sceptic-clock-feedback-pe_max-preconvolve_fse_groupfixed/pe_max/')
pemeta <- read_csv("pe_max_cluster_metadata.csv")
pemeta$label <- substr(pemeta$label,22,100)
pemeta_overall <- pemeta[pemeta$l2_contrast == 'overall' & pemeta$l3_contrast == 'Intercept' & pemeta$model == 'Intercept-Age',]
pebetas <- read_csv("pe_max_roi_betas.csv")
pe <- as.tibble(pebetas[pebetas$l2_contrast == 'overall' & pebetas$l3_contrast == 'Intercept' & pebetas$model == 'Intercept-Age',1:3]) %>% filter(cluster_number<8 | cluster_number == 10 | cluster_number == 11)
# head(merge(h,meta))
perois_list <- distinct(pemeta_overall[c(1:7, 10:11),c(5,12)])

# inspect distributions
# for some reason, the clusters do not seem to fit the map -- check with MNH (big clusters broken down?) !!
perois <- inner_join(pe,pemeta_overall)
perois$labeled_cluster <- paste(perois$cluster_number,perois$label)
pemeta_overall$labeled_cluster <- paste(pemeta_overall$cluster_number,pemeta_overall$label)
ggplot(perois,aes(scale(cope_value))) + geom_histogram() + facet_wrap(~labeled_cluster)

pe_labeled <- inner_join(pe,perois_list)
pe_labeled$labeled_cluster <- paste(pe_labeled$cluster_number,pe_labeled$label)
pe_num <- select(pe_labeled,c(1,2,3))
pe_labeled <- select(pe_labeled,c(1,3,5))

pe_wide <- spread(pe_labeled,labeled_cluster,cope_value)
pe_wide_num <- spread(pe_num,cluster_number,cope_value)

# some outliers, let's winsorize for now
pe_wide <- pe_wide %>% mutate_if(is.double, winsor,trim = .075)
# pe_wide_num <- pe_wide_num %>% mutate_if(is.double, winsor,trim = .075)

pejust_rois <- pe_wide[,2:ncol(pe_wide)]
pejust_rois_num <- pe_wide_num[,2:ncol(pe_wide_num)]

# winsorize to deal with beta ouliers

# non-parametric correlations to deal with outliers
peclust_cor <- corr.test(pejust_rois,method = 'pearson', adjust = 'none')
# parametric correlations on winsorised betas
# clust_cor <- cor(just_rois_w,method = 'pearson')

# setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
# pdf("pe_cluster_corr_fixed.pdf", width=12, height=12)
# corrplot(peclust_cor$r, cl.lim=c(-1,1),
#          method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
#          order = "hclust", diag = FALSE,
#          addCoef.col="black", addCoefasPercent = FALSE,
#          p.mat = peclust_cor$p, sig.level=0.05, insig = "blank")
# dev.off()

mpe <- nfactors(peclust_cor$r, n=5, rotate = "oblimin", diagonal = FALSE,fm = "pa", n.obs = 70, SMC = FALSE)
pe.fa = psych::fa(pejust_rois_num, nfactors=2, rotate = "varimax", fm = "pa")

# library("lavaan")
# msyn <- '
# cort_str =~ 1*`1` + `11` + `2` + `3` +
#             `4` + `5` +
#             `6` #putting the 1* here for clarity, but it is the lavaan default
# hipp =~ 1*`10` + `7`
# cort_str ~~ 0*hipp #force orthogonal (uncorrelated) factors
# cort_str ~~ cort_str #explicitly indicate that lavaan should estimate a free parameters for factor variances
# hipp ~~ hipp
# '
# msyn_cor <- '
# cort_str =~ 1*`1` + `11` + `2` + `3` +
#             `4` + `5` +
# `6` #putting the 1* here for clarity, but it is the lavaan default
# hipp =~ 1*`10` + `7`
# cort_str ~~ hipp #force orthogonal (uncorrelated) factors
# cort_str ~~ cort_str #explicitly indicate that lavaan should estimate a free parameters for factor variances
# hipp ~~ hipp
# '
# 
# 
# mcfa <- cfa(msyn, pejust_rois_num)
# summary(mcfa, standardized=TRUE)
# mcfa_cor <- cfa(msyn_cor, pejust_rois_num)
# summary(mcfa_cor, standardized=TRUE)
# anova(mcfa,mcfa_cor)

pe.fa = psych::fa(pejust_rois, nfactors=2)
pefscores <- factor.scores(pejust_rois, pe.fa)$scores
pe_wide$pe_f1_cort_str <- pefscores[,1]
pe_wide$pe_f2_hipp <- pefscores[,2]

dvhkpe_wide <- inner_join(dvhkf_wide,pe_wide[,c("feat_input_id","pe_f1_cort_str", "pe_f2_hipp")])

# add entropy change betas.  Having looked at the maps vs. PE, only signed H change and H pos change seem promising; H neg is slim and RTvmax change a shadow of PE
#####
# add signed H change
setwd('~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/compiled_outputs/change_betas/sceptic-clock-feedback-v_entropy_change-preconvolve_fse_groupfixed/v_entropy_change/')
dhmeta <- read_csv("v_entropy_change_cluster_metadata.csv")
dhmeta$label <- substr(dhmeta$label,22,100)
dhmeta_overall <- dhmeta[dhmeta$l2_contrast == 'overall' & dhmeta$l3_contrast == 'Intercept' & dhmeta$model == 'Intercept-Age',]
dhbetas <- read_csv("v_entropy_change_roi_betas.csv")
# only positive clusters
dh <- as.tibble(dhbetas[dhbetas$l2_contrast == 'overall' & dhbetas$l3_contrast == 'Intercept' & dhbetas$model == 'Intercept-Age',1:3]) %>% filter(cluster_number<7 | cluster_number==8 
                                                                                                                                                  | cluster_number==9 | cluster_number==11 | cluster_number==12
                                                                                                                                                  | cluster_number==13 | cluster_number==14  )
# head(merge(h,meta))
dhrois_list <- distinct(dhmeta_overall[c(1:14),c(5,12)])

# inspect distributions
# for some reason, the clusters do not seem to fit the map -- check with MNH (big clusters broken down?) !!
dhrois <- inner_join(dh,dhmeta_overall)
dhrois$labeled_cluster <- paste(dhrois$cluster_number,dhrois$label)
dhmeta_overall$labeled_cluster <- paste(dhmeta_overall$cluster_number,dhmeta_overall$label)
ggplot(dhrois,aes(scale(cope_value))) + geom_histogram() + facet_wrap(~labeled_cluster)

dh_labeled <- inner_join(dh,dhrois_list)
dh_labeled$labeled_cluster <- paste(dh_labeled$cluster_number,dh_labeled$label)
dh_labeled <- select(dh_labeled,c(1,3,5))

dh_wide <- spread(dh_labeled,labeled_cluster,cope_value)

# some outliers, let's winsorize for now
dh_wide <- dh_wide %>% mutate_if(is.double, winsor,trim = .075)

dhjust_rois <- dh_wide[,2:ncol(dh_wide)]
# winsorize to deal with beta ouliers

# non-parametric correlations to deal with outliers
dhclust_cor <- corr.test(dhjust_rois,method = 'pearson', adjust = 'none')
# parametric correlations on winsorised betas
# clust_cor <- cor(just_rois_w,method = 'pearson')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("dh_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(dhclust_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = dhclust_cor$p, sig.level=0.05, insig = "blank")
dev.off()
# looks like a single dimension

mdh <- nfactors(dhclust_cor$r, n=5, rotate = "oblimin", diagonal = FALSE,fm = "pa", n.obs = 70, SMC = FALSE)
dh.fa = psych::fa(dhjust_rois, nfactors=2, rotate = "oblimin", fm = "pa")

# dh.pca = prcomp((dhjust_rois),scale = TRUE, center = TRUE)
# dh_wide$dh_pc1 <- dh.pca$x[,1]
# dh_wide$dh_pc2 <- dh.pca$x[,2]

dhfscores <- factor.scores(dhjust_rois, dh.fa)$scores
dh_wide$dh_f1_co_bg <- dhfscores[,1]
dh_wide$dh_f2_dan <- dhfscores[,2]
dvhkpedh_wide <- inner_join(dvhkpe_wide,dh_wide[,c("feat_input_id","dh_f1_co_bg", "dh_f2_dan")])

# only negative clusters
dh <- as.tibble(dhbetas[dhbetas$l2_contrast == 'overall' & dhbetas$l3_contrast == 'Intercept' & dhbetas$model == 'Intercept-Age',1:3]) %>% filter(cluster_number==7 | cluster_number==10)
# head(merge(h,meta))
dhrois_list <- distinct(dhmeta_overall[c(7,10),c(5,12)])

# inspect distributions
# for some reason, the clusters do not seem to fit the map -- check with MNH (big clusters broken down?) !!
dhrois <- inner_join(dh,dhmeta_overall)
dhrois$labeled_cluster <- paste(dhrois$cluster_number,dhrois$label)
dhmeta_overall$labeled_cluster <- paste(dhmeta_overall$cluster_number,dhmeta_overall$label)
ggplot(dhrois,aes(scale(cope_value))) + geom_histogram() + facet_wrap(~labeled_cluster)

dh_labeled <- inner_join(dh,dhrois_list)
dh_labeled$labeled_cluster <- paste(dh_labeled$cluster_number,dh_labeled$label)
dh_labeled <- select(dh_labeled,c(1,3,5))

dh_wide <- spread(dh_labeled,labeled_cluster,cope_value)

# some outliers, let's winsorize for now
dh_wide <- dh_wide %>% mutate_if(is.double, winsor,trim = .075)

dhjust_rois <- dh_wide[,2:ncol(dh_wide)]
# winsorize to deal with beta ouliers

# non-parametric correlations to deal with outliers
dhclust_cor <- corr.test(dhjust_rois,method = 'pearson', adjust = 'none')
# parametric correlations on winsorised betas
# clust_cor <- cor(just_rois_w,method = 'pearson')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("dh_neg_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(dhclust_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = dhclust_cor$p, sig.level=0.05, insig = "blank")
dev.off()

# two regions, one factor
dh.fa = psych::fa(dhjust_rois, nfactors=1, rotate = "oblimin", fm = "pa")
dhfscores <- factor.scores(dhjust_rois, dh.fa)$scores
dh_wide$dh_f_neg_vmpfc_precun <- dhfscores[,1]


dvhkpedh_wide <- inner_join(dvhkpedh_wide,dh_wide[,c("feat_input_id","dh_f_neg_vmpfc_precun")])

# add pos H change
setwd('~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/compiled_outputs/change_betas/sceptic-clock-feedback-v_entropy_change_pos-preconvolve_fse_groupfixed/v_entropy_change_pos/')
dhpmeta <- read_csv("v_entropy_change_pos_cluster_metadata.csv")
dhpmeta$label <- substr(dhpmeta$label,22,100)
dhpmeta_overall <- dhpmeta[dhpmeta$l2_contrast == 'overall' & dhpmeta$l3_contrast == 'Intercept' & dhpmeta$model == 'Intercept-Age',]
dhpbetas <- read_csv("v_entropy_change_pos_roi_betas.csv")
# only positive clusters
dhp <- as.tibble(dhpbetas[dhpbetas$l2_contrast == 'overall' & dhpbetas$l3_contrast == 'Intercept' & dhpbetas$model == 'Intercept-Age',1:3]) %>% filter(cluster_number<15 & cluster_number != 12 & cluster_number !=4)
# head(merge(h,meta))
dhprois_list <- distinct(dhpmeta_overall[c(1:3,5:11,13:14),c(5,12)])

# inspect distributions
# for some reason, the clusters do not seem to fit the map -- check with MNH (big clusters broken down?) !!
dhprois <- inner_join(dhp,dhpmeta_overall)
dhprois$labeled_cluster <- paste(dhprois$cluster_number,dhprois$label)
dhpmeta_overall$labeled_cluster <- paste(dhpmeta_overall$cluster_number,dhpmeta_overall$label)
ggplot(dhprois,aes(scale(cope_value))) + geom_histogram() + facet_wrap(~labeled_cluster)

dhp_labeled <- inner_join(dhp,dhprois_list)
dhp_labeled$labeled_cluster <- paste(dhp_labeled$cluster_number,dhp_labeled$label)
dhp_labeled <- select(dhp_labeled,c(1,3,5))

dhp_wide <- spread(dhp_labeled,labeled_cluster,cope_value)

# some outliers, let's winsorize for now
dhp_wide <- dhp_wide %>% mutate_if(is.double, winsor,trim = .05)

dhpjust_rois <- dhp_wide[,2:ncol(dhp_wide)]
# winsorize to deal with beta ouliers

# non-parametric correlations to deal with outliers
dhpclust_cor <- corr.test(dhpjust_rois,method = 'pearson', adjust = 'none')
# parametric correlations on winsorised betas
# clust_cor <- cor(just_rois_w,method = 'pearson')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("dhp_cluster_corr_fixed.pdf", width=12, height=12)
corrplot(dhpclust_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = dhpclust_cor$p, sig.level=0.05, insig = "blank")
dev.off()
# looks like a single dimension

# dhp.pca = prcomp((dhpjust_rois),scale = TRUE, center = TRUE)
# dhp_wide$dhp_pc1 <- dhp.pca$x[,1]
# dhp_wide$dhp_pc2 <- dhp.pca$x[,2]
mdhp <- nfactors(dhpclust_cor$r, n=5, rotate = "oblimin", diagonal = FALSE,fm = "mle", n.obs = 70, SMC = FALSE)
dhp.fa = psych::fa(dhpjust_rois, nfactors=1, rotate = "oblimin", fm = "mle")

# dhp.fa = psych::fa(dhpjust_rois, nfactors=4, fm = "mle")
dhpfscores <- factor.scores(dhpjust_rois, dhp.fa)$scores
dhp_wide$dhp_f1_all <- dhpfscores[,1]

# dhp_wide$dhp_f3_ventr_stream_cerebell <- dhpfscores[,3]
# dhp_wide$dhp_f2_str <- dhpfscores[,2]
# dhp_wide$dhp_f1_dlpfc_r <- dhpfscores[,1]
# dhp_wide$dhp_f4_prefront_l <- dhpfscores[,4]

dvhkpedh_wide <- inner_join(dvhkpedh_wide,dhp_wide[,c("feat_input_id","dhp_f1_all")])


#####
# add ids
map_df  <- as.tibble(read.csv("~/Box Sync/skinner/projects_analyses/SCEPTIC/fMRI_paper/signals_review/MMClock_aroma_preconvolve_fse_groupfixed/sceptic-clock-feedback-v_entropy-preconvolve_fse_groupfixed/v_entropy/v_entropy-Intercept_design.txt", sep=""))

pc_scores <- inner_join(dvhkpedh_wide,map_df[,c(1:2,4:15)])
pc_scores$id <- pc_scores$ID


# get trial_level data
trial_df <- read_csv("~/code/clock_analysis/fmri/data/mmclock_fmri_decay_factorize_selective_psequate_mfx_trial_statistics.csv.gz")
trial_df <- trial_df %>%
  group_by(id, run) %>%  dplyr::mutate(rt_swing = abs(c(NA, diff(rt_csv))),
                                       rt_swing_lr = abs(log(rt_csv/lag(rt_csv))),
                                       rt_lag = lag(rt_csv) ,
                                       rt_swing_lag = lag(rt_swing),
                                       omission_lag = lag(score_csv==0),
                                       rt_vmax_lag = lag(rt_vmax),
                                       run_trial=1:50) %>% ungroup() #compute rt_swing within run and subject

# performance
sum_df <- trial_df %>% group_by(id) %>% dplyr::summarize(total_earnings = sum(score_csv)) %>% arrange(total_earnings)
beta_sum <- inner_join(pc_scores,sum_df)
# plot(beta_sum$h_f1_fp,beta_sum$total_earnings)
# plot(beta_sum$h_f2_neg_paralimb,beta_sum$total_earnings)
# plot(beta_sum$v_f1_neg_cog,beta_sum$total_earnings)
# plot(beta_sum$v_f2_paralimb,beta_sum$total_earnings)
# plot(beta_sum$k_f1_IPL_ventr_stream,beta_sum$total_earnings)
# plot(beta_sum$k_f2_prefrontal_bg,beta_sum$total_earnings)
# plot(beta_sum$pe_f1_cort_str,beta_sum$total_earnings)
# plot(beta_sum$pe_f2_hipp,beta_sum$total_earnings)

# model parameters
params <- read_csv("~/code/clock_analysis/fmri/data/mmclock_fmri_decay_factorize_selective_psequate_mfx_sceptic_global_statistics.csv")
sub_df <- inner_join(beta_sum,params)
params_beta <- sub_df[,c("v_f1_neg_cog","v_f2_paralimb","h_f1_fp", "h_f2_neg_paralimb","h_HippAntL",
                         "d_f1_FP_SMA","d_f2_VS","d_f3_ACC_ins", 
                         "k_f1_all_pos",
                         "kf_f1_pos", "kf_f2_vmpfc_precun", 
                         "pe_f1_cort_str", "pe_f2_hipp", 
                         "dh_f1_co_bg","dh_f2_dan","dh_f_neg_vmpfc_precun",
                         "dhp_f1_all", 
                         "total_earnings", "LL", "alpha", "gamma", "beta")]
param_cor <- corr.test(params_beta,method = 'pearson', adjust = 'none')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("dvhkfpedh_beta_param_corr_fixed.pdf", width=12, height=12)
corrplot(param_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = param_cor$p, sig.level=0.05, insig = "blank")
dev.off()

# merge into trial-level data
df <- inner_join(trial_df,sub_df)
df$rewFunc <- relevel(as.factor(df$rewFunc),ref = "CEV")
df$rewFuncIEVsum <- df$rewFunc
contrasts(df$rewFuncIEVsum) <- contr.sum
colnames(contrasts(df$rewFuncIEVsum)) <- c('CEV','CEVR', 'DEV')
# dichotomize betas for plotting
df$h_fp <- 'low'
df$h_fp[df$h_f1_fp>0] <- 'high'
df$low_h_paralimbic <- 'low'
df$low_h_paralimbic[df$h_f2_neg_paralimb<0] <- 'high'

df$v_paralimbic <- 'low'
df$v_paralimbic[df$v_f2_paralimb>0] <- 'high'
#NB: v_f2_paralimb is mostly vlPFC driven now...
df$low_v_fp_acc_vlpfc <- 'low'
df$low_v_fp_acc_vlpfc[df$v_f1_neg_cog<0] <- 'high'

df$learning_epoch <- 'trials 1-10'
df$learning_epoch[df$run_trial>10] <- 'trials 11-50'




# obtain within-subject v_max and entropy: correlated at -.37

df <- df %>% group_by(id,run) %>% mutate(v_max_wi = scale(v_max),
                                         v_max_wi_lag = lag(v_max_wi),
                                         v_entropy_wi = scale(v_entropy),
                                         v_max_b = mean(na.omit(v_max)),
                                         v_entropy_b = mean(na.omit(v_entropy)),
                                         rt_change = rt_csv - rt_lag,
                                         pe_max_lag = lag(pe_max), 
                                         abs_pe_max_lag = abs(pe_max_lag), 
                                         rt_vmax_change = rt_vmax - rt_vmax_lag
)

# correlate between-subject V and H with clusters
b_df <- df %>% group_by(id) %>% dplyr::summarise(v_maxB = mean(v_max, na.rm = T),
                                          v_entropyB = mean(v_entropy, na.rm = T))

sub_df <- inner_join(sub_df, b_df, by = 'id')
bdf <- sub_df[,c("v_f1_neg_cog","v_f2_paralimb","h_f1_fp", "h_f2_neg_paralimb",
                 "d_f1_FP_SMA","d_f2_VS","d_f3_ACC_ins", 
                 "k_f1_all_pos",
                 "pe_f1_cort_str", "pe_f2_hipp",
                 "kf_f1_pos", "kf_f2_vmpfc_precun",
                 "total_earnings", "LL", "alpha", "gamma", "beta", "v_maxB", "v_entropyB")]
b_cor <- corr.test(bdf,method = 'pearson', adjust = 'none')

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
pdf("between_subject_v_h_kf_pe_beh_corr_fixed.pdf", width=12, height=12)
corrplot(b_cor$r, cl.lim=c(-1,1),
         method = "circle", tl.cex = 1.5, type = "upper", tl.col = 'black',
         order = "hclust", diag = FALSE,
         addCoef.col="black", addCoefasPercent = FALSE,
         p.mat = b_cor$p, sig.level=0.05, insig = "blank")
dev.off()
df$d_f1_FP_SMAresp <- 'low'
df$d_f1_FP_SMAresp[df$d_f1_FP_SMA>0] <- 'high'
df$d_f2_VSresp <- 'low'
df$d_f2_VSresp[df$d_f2_VS>0] <- 'high'
df$d_f3_ACC_ins_resp <- 'low'
df$d_f3_ACC_ins_resp[df$d_f3_ACC_ins>0] <- 'high'
df$d_f2_VSresp <- as.factor(df$d_f2_VSresp)
df$d_f2_VSresp <- relevel(df$d_f2_VSresp, ref = 'low') 

df$k_f1_all_pos_resp <- 'low'
df$k_f1_all_pos_resp[df$k_f1_all_pos>0] <- 'high'

df$kf_f1_pos_resp <- 'low'
df$kf_f1_pos_resp[df$kf_f1_pos>0] <- 'high'
df$kf_f2_vmpfc_precun_resp <- 'low'
df$kf_f2_vmpfc_precun_resp[df$kf_f2_vmpfc_precun>0] <- 'high'

df$pe_f1_cort_str_resp <- 'low'
df$pe_f1_cort_str_resp[df$pe_f1_cort_str>0] <- 'high'
df$pe_f2_hipp_resp <- 'low'
df$pe_f2_hipp_resp[df$pe_f2_hipp>0] <- 'high'

df$h_HippAntL_resp <- 'low'
df$h_HippAntL_resp[df$h_HippAntL<mean(df$h_HippAntL)] <- 'high'
df$last_outcome <- NA
df$last_outcome[df$omission_lag] <- 'Omission'
df$last_outcome[!df$omission_lag] <- 'Reward'

# circular, but just check to what extent each area conforms to SCEPTIC-SM: looks like there is an interaction, both need to be involved again
# ggplot(df, aes(run_trial, v_entropy_wi, color = low_h_paralimbic, lty = h_fp)) + geom_smooth(method = "loess") #+ facet_wrap(~gamma>0)
# # I think this means again that H estimates are more precise for high-paralimbic people, esp. late in learning
# ggplot(df, aes( v_entropy_wi,log(rt_swing), color = low_h_paralimbic, lty = h_fp)) + geom_smooth(method = "gam") + facet_wrap(~learning_epoch)
# ggplot(df, aes( v_max_wi,log(rt_swing), color = low_h_paralimbic, lty = h_fp)) + geom_smooth(method = "gam") + facet_wrap(~run_trial > 10)
# 
# Okay, some behavioral relevance of KLD
# ggplot(df, aes(run_trial, v_entropy_wi, color = k_f1_all_pos_resp)) + geom_smooth(method = "loess")


save(file = 'trial_df_and_vhdkfpe_clusters.Rdata', df)

