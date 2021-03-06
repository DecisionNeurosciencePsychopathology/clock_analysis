library(dplyr)
library(tidyverse)
library(psych)
library(corrplot)
library(lme4)
library(lmerTest)
library(ggpubr)
library(grid)
# source('~/code/Rhelpers/')
setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/')
load('trial_df_and_vhdkfpe_clusters.Rdata')
df1 <- df[,c(1:4,5:118)]
load('trial_df_and_vhd_bs.Rdata')
shared <- intersect(names(df), names(df1))
shared <- shared[c(2:40, 60:70)] # remove confusing vars
df <- inner_join(df,df1, by = shared)

save(file = 'clusters_and_beta_series.Rdata', df)


vif.lme <- function (fit) {
  ## adapted from rms::vif
  v <- vcov(fit)
  nam <- names(fixef(fit))
  ## exclude intercepts
  ns <- sum(1 * (nam == "Intercept" | nam == "(Intercept)"))
  if (ns > 0) {
    v <- v[-(1:ns), -(1:ns), drop = FALSE]
    nam <- nam[-(1:ns)] }
  d <- diag(v)^0.5
  v <- diag(solve(v/(d %o% d)))
  names(v) <- nam
  v }

# check VIFs of significant effects
screen.lmerTest <- function (mod,p=NULL) {
  if (is.null(p)) {p <- .05}
  c1 <- as.data.frame(coef(summary(mod))[,4:5])
  dd <- cbind(c1[2:nrow(c1),],as.data.frame(vif.lme(mod)))
  names(dd)[3] <- 'VIF'
  dd$`Pr(>|t|)` <- as.numeric(dd$`Pr(>|t|)`)
  print(dd[dd$`Pr(>|t|)`<p,c(1,3)], digits = 3)}
#####

# for further analyses, we want the following regions:
# hb_f1_DAN (alt. vb_f1_lo_DAN_vlPFC)
# hb_f2_paralimbic (alt vb_f2_hi_paralimbic)
# db_f4_ACC_ins -- compression
# db_f1_rIFG_SMA -- ?overload



dfc <- na.omit(df[df$rt_swing>0,])

# parallel to the beta models

####### NEW
# follow cluster beta analyses
# mfh <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + omission_lag  + h_ant_hipp_b_f + h_HippAntL)^3 + 
#               (scale(-1/run_trial) + scale(rt_lag) + omission_lag  + peb_f2_p_hipp + pe_f2_hipp)^3 + 
#                (1|id/run), df)
# screen.lmerTest(mfh)
# 
# # add region interactions
# mfh1 <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + omission_lag  + h_ant_hipp_b_f + h_HippAntL+ peb_f2_p_hipp + pe_f2_hipp)^3 + 
#               (1|id/run), df)
# screen.lmerTest(mfh1)

# remove the clusters
mfh2 <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + omission_lag  + h_ant_hipp_b_f + peb_f2_p_hipp)^3 + 
               (1|id/run), df)
screen.lmerTest(mfh2)

# simple model by contingency
mfh3 <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + omission_lag + rewFuncIEVsum + h_ant_hipp_b_f_lag + peb_f2_p_hipp_lag)^3 + 
               (1|id/run), df)
screen.lmerTest(mfh3)

# ## "model-free" RT swings analyses

wh1 <- lmer(rt_swing ~ (scale(-1/run_trial) + h_ant_hipp_b_f_lag + peb_f2_p_hipp_lag)^2 + 
              (1|id/run), df)
screen.lmerTest(wh1)
summary(wh1)
######
 

# mf1 <- lmer(log(rt_swing) ~ scale(-1/run_trial) +  rewFuncIEVsum + (1|id/run), dfc)
# screen.lmerTest(mf1)
# ## favorite simple model ##
# mf2 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + rewFuncIEVsum + hb_f1_DAN_vlPFC + hb_f2_neg_paralimb + gamma)^3 + 
#               rt_lag + (1|id/run), dfc)
# screen.lmerTest(mf2)
# ##
# mf3 <- lmer(log(rt_swing) ~ scale(-1/run_trial) + rewFuncIEVsum + hb_f1_DAN_vlPFC + hb_f2_neg_paralimb + db_f1_rIFG_rSMA + db_f4_ACC_ins + (1|id/run), dfc)
# screen.lmerTest(mf3)
# mf4 <- lmer(log(rt_swing) ~ scale(-1/run_trial) + rewFuncIEVsum + hb_f1_DAN_vlPFC + hb_f2_neg_paralimb + 
#               vb_f3_hi_blITG + vb_f4_lo_cerebell_crus + vb_f5_lo_ACC + 
#               db_f1_rIFG_rSMA + db_f2_VS + db_f3_occ_parietal + db_f4_ACC_ins + (1|id/run), dfc)
# screen.lmerTest(mf4)
# # model-free RT
# mfr1 <- lmer(rt_csv ~ (scale(-1/run_trial) +  rewFuncIEVsum)^2 + (1|id/run), dfc)
# screen.lmerTest(mfr1)
# ## favorite simple model ##
# mfr2 <- lmer(rt_csv ~ (scale(-1/run_trial) + rewFuncIEVsum + hb_f1_DAN_vlPFC + hb_f2_neg_paralimb + gamma)^3 + (1|id/run), dfc)
# screen.lmerTest(mfr2)
# ##
# mfr3 <- lmer(rt_csv ~ (scale(-1/run_trial) + rewFuncIEVsum + hb_f1_DAN_vlPFC + hb_f2_neg_paralimb + db_f1_rIFG_rSMA + db_f4_ACC_ins)^3 + (1|id/run), dfc)
# screen.lmerTest(mfr3)
# # just paralimbic and ACC
# mfr3a <- lmer(rt_csv ~ (scale(-1/run_trial) + rewFuncIEVsum + hb_f2_neg_paralimb + db_f4_ACC_ins)^4 + (1|id/run), dfc)
# screen.lmerTest(mfr3a)
# # 
# ggplot(dfc, aes(hb_f2_neg_paralimb,rt_csv, color = db_f4_ACC_ins>0)) + geom_smooth(method = "loess")
# ggplot(dfc, aes(hb_f1_DAN_vlPFC,log(rt_swing), color = gamma>0)) + geom_smooth(method = "loess")
# ggplot(dfc, aes(hb_f2_neg_paralimb,log(rt_swing),color = gamma>0)) + geom_smooth(method = "loess")
# 
# mfr4 <- lmer(rt_csv ~ scale(-1/run_trial) + rewFuncIEVsum + hb_f1_DAN_vlPFC + hb_f2_neg_paralimb + 
#               vb_f3_hi_blITG + vb_f4_lo_cerebell_crus + vb_f5_lo_ACC + 
#               db_f1_rIFG_rSMA + db_f2_VS + db_f3_occ_parietal + db_f4_ACC_ins + (1|id/run), dfc)
# screen.lmerTest(mf4)
# 
# 
# model-based

###### NEW, hippocampal, following cluster betas
mbhipp1a <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi +rt_vmax_change +  h_ant_hipp_b_f_lag)^2 + 
                  scale(rt_lag):omission_lag:h_ant_hipp_b_f_lag +
                  scale(rt_lag)*omission_lag*scale(rt_vmax_lag)*h_ant_hipp_b_f_lag + 
                  scale(rt_vmax_lag):v_max_wi_lag:h_ant_hipp_b_f_lag + 
                  scale(-1/run_trial):scale(rt_vmax_lag):h_ant_hipp_b_f_lag +  
                  (1|id/run), df)
screen.lmerTest(mbhipp1a)

# 
mb_ah_rtvmax <- lmer(rt_csv ~ scale(rt_vmax) * h_ant_hipp_b_f_lag + 
                   (1|id/run), df)
screen.lmerTest(mb_ah_rtvmax)
# # do we see it with the high-value network?  No!
# mb_v2_rtvmax <- lmer(rt_csv ~ scale(rt_vmax_lag) * vb_f2_hi_vmPFC_cOFC + 
#                        (1|id/run), df)
# screen.lmerTest(mb_v2_rtvmax)

# no substantial interaction
mb_ph_rtvmax <- lmer(rt_csv ~ scale(rt_vmax) * peb_f2_p_hipp_lag + 
                       (1|id/run), df)
screen.lmerTest(mb_ph_rtvmax)

mbhipp1p <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi_lag +rt_vmax_change_lag + peb_f2_p_hipp_lag)^2 + 
                  scale(rt_lag):omission_lag:peb_f2_p_hipp_lag +
                  scale(rt_lag)*omission_lag*scale(rt_vmax_lag)*peb_f2_p_hipp_lag +
                  scale(rt_vmax_lag):v_max_wi_lag:peb_f2_p_hipp_lag +
                  scale(-1/run_trial):scale(rt_vmax_lag):peb_f2_p_hipp_lag +
                  v_max_b + v_entropy_b +  (1|id/run), df)
screen.lmerTest(mbhipp1p)


mbhipp1 <- lmer(rt_csv ~ (scale(-1/run_trial)  + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + h_ant_hipp_b_f_lag + peb_f2_p_hipp_lag)^2 + 
                scale(rt_lag)*omission_lag*scale(rt_vmax_lag)*h_ant_hipp_b_f_lag + scale(rt_lag)*omission_lag*scale(rt_vmax_lag)*peb_f2_p_hipp_lag +
                 scale(rt_vmax_lag):v_max_wi_lag:h_ant_hipp_b_f_lag + scale(rt_vmax_lag):v_max_wi_lag:peb_f2_p_hipp_lag +
                 scale(-1/run_trial):scale(rt_vmax_lag):h_ant_hipp_b_f_lag +  scale(-1/run_trial):scale(rt_vmax_lag):peb_f2_p_hipp_lag +
                 v_max_b + v_entropy_b + (1|id/run), df)
screen.lmerTest(mbhipp1, .01)


# this slowing to AH*PH is kinda shocking.  Is it also seen on the next trial?  Not at all -- must be the result of convolution
mbhipp1_1 <- lmer(rt_next ~ (scale(-1/run_trial)  + scale(rt_csv) + scale(rt_vmax) + v_max_wi + v_entropy_wi + h_ant_hipp_b_f_lag + peb_f2_p_hipp_lag)^2 + 
                  v_max_b + v_entropy_b + (1|id/run), df)
screen.lmerTest(mbhipp1_1, .01)

# how do they predict next RT?
rt_next_hipp<- lmer(rt_csv ~ (rt_vmax + h_ant_hipp_b_f + peb_f2_p_hipp)^2 + 
                 (1|id/run), df)
screen.lmerTest(rt_next_hipp, .01)




# simplified model
mbhipp1simp <- lmer(rt_csv ~ (scale(-1/run_trial)  + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi +rt_vmax_change + h_ant_hipp_b_f_lag + peb_f2_p_hipp_lag)^2 + 
                  v_max_b + v_entropy_b + (1|id/run), df)
screen.lmerTest(mbhipp1simp, .01)


 
# both anterior and posterior
mbhipp2 <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi +rt_vmax_change +  h_ant_hipp_b_f_lag)^2 + 
                  scale(rt_lag):omission_lag:h_ant_hipp_b_f_lag +
                  scale(rt_lag)*omission_lag*scale(rt_vmax_lag)*h_ant_hipp_b_f_lag + 
                  scale(rt_vmax_lag):v_max_wi_lag:h_ant_hipp_b_f_lag + 
                  scale(-1/run_trial):scale(rt_vmax_lag):h_ant_hipp_b_f_lag +  
                  (scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi +rt_vmax_change + peb_f2_p_hipp_lag)^2 + 
                  scale(rt_lag):omission_lag:peb_f2_p_hipp_lag +
                  scale(rt_lag)*omission_lag*scale(rt_vmax_lag)*peb_f2_p_hipp_lag +
                  scale(rt_vmax_lag):v_max_wi_lag:peb_f2_p_hipp_lag +
                  scale(-1/run_trial):scale(rt_vmax_lag):peb_f2_p_hipp_lag +
                  v_max_b + v_entropy_b +  (1|id/run), df)
screen.lmerTest(mbhipp2, .05)
# 

# 
# e1 <- summary(em1 <- emmeans::emtrends(mbhipp1,var = 'rt_lag', specs = c("omission_lag", "rt_vmax_lag","peb_f2_p_hipp"), 
#                               at  = list(peb_f2_p_hipp = c(-1,1), rt_vmax_lag = c(10,20,30))), horiz = F)
# 
# ggplot(e1, aes(rt_vmax_lag, rt_lag.trend, color = omission_lag)) + geom_line() + facet_wrap(~peb_f2_p_hipp)

setwd('~/code/clock_analysis/fmri/keuka_brain_behavior_analyses/plots/')

pdf("lose_shift.pdf", width = 12, height = 10)
ggplot(df[!is.na(df$peb_f2_p_hipp_lag) & !is.na(df$rt_vmax_lag) ,], aes(rt_lag, rt_csv, color = omission_lag, lty = rt_vmax_lag>20)) + geom_smooth(method = 'glm') #+ facet_wrap(~rewFunc)
dev.off()

pdf("p_hipp_lose_shift.pdf", width = 12, height = 10)
ggplot(df[!is.na(df$peb_f2_p_hipp_lag) & !is.na(df$rt_vmax_lag) ,], aes(rt_lag, rt_csv, color = peb_f2_p_hipp_lag>0, lty = rt_vmax_lag>20)) + geom_smooth(method = 'glm') + facet_wrap(~omission_lag)
dev.off()

# first, does DAN improve prediction of RTs and EXPLAIN effects of v_entropy_wi?
# it improves prediction, but seems to contain information independent of entropy_wi...
w0 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma)^2 +
             v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
screen.lmerTest(w0)

w0dan <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + hb_f1_DAN_vlPFC + gamma)^2 +
             v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
screen.lmerTest(w0dan)
anova(w0, w0dan)

w0hipp <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + h_ant_hipp_b_f + hb_f1_DAN_vlPFC + gamma)^2 +
                v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
screen.lmerTest(w0dan)
anova(w0, w0dan)


# 
# w1 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma)^2 + v_max_b + v_entropy_b +scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w1)
# w2h <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + hb_f1_DAN_vlPFC + gamma)^3 + 
#               (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + hb_f2_neg_paralimb + gamma)^2  + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w2h)
# # reduced model without entropy -- now h1 interacts with v_max, but just barely
# w1h <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi +  hb_f1_DAN_vlPFC + gamma)^2 + 
#               (scale(-1/run_trial) + omission_lag + v_max_wi +  hb_f2_neg_paralimb + gamma)^2  + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w1h)
# 
# # the same as full
# w1ha <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_entropy_wi +  hb_f1_DAN_vlPFC + gamma)^2 + 
#               (scale(-1/run_trial) + omission_lag + v_entropy_wi +  hb_f2_neg_paralimb + gamma)^2  + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w1ha)
# 
# # control for current RT because of RT convolution
# # RT swing effect stands essentially unchanged
# w1hb <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_entropy_wi +  hb_f1_DAN_vlPFC + gamma)^2 + 
#                (scale(-1/run_trial) + omission_lag + v_entropy_wi +  hb_f2_neg_paralimb + gamma)^2  + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_csv) + (1|id/run), dfc)
# screen.lmerTest(w1hb)
# 
# 
# # screen factors in separate models b/c collinearity
# w2d1 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f1_rIFG_rSMA + gamma)^2 +scale(rt_swing_lag) +scale(rt_swing_lag) +  v_max_b + v_entropy_b + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w2d1)
# # VS seems to accentuate the effect of v_max
# w2d2 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f2_VS + gamma)^2 + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w2d2)
# # effect of d3
# w2d3 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f3_occ_parietal + gamma)^2 + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w2d3)
# # effect of d4 relatively subtle
# w2d4 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f4_ACC_ins + gamma)^2 + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w2d4,.1)
# # no effect of ITG/v3
# w2v3 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + vb_f3_hi_blITG + gamma)^2 + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w2v3)
# # no effect of cerebellar v4
# w2v4 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + vb_f4_lo_cerebell_crus + gamma)^2 + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w2v4)
# # the more properly anterior v5 ACC predicts RT and interacts with gamma
# w2v5 <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + vb_f5_lo_ACC + gamma)^2 + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w2v5)
# 
# # conclusions: focus on d1, d4 (despite moderate effect), v5
# 
# 
# w3hd <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + hb_f1_DAN_vlPFC + gamma)^2 + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f1_rIFG_rSMA + gamma)^2  + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f4_ACC_ins + gamma)^2  + 
#                 v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w3hd)
# w4vhd <- lmer(log(rt_swing) ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + hb_f1_DAN_vlPFC + gamma)^2 + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + hb_f2_neg_paralimb + gamma)^2  + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + vb_f3_hi_blITG + gamma)^2  + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + vb_f4_lo_cerebell_crus + gamma)^2  + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + vb_f5_lo_ACC + gamma)^2  + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f1_rIFG_rSMA + gamma)^2  + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f2_VS + gamma)^2  + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f3_occ_parietal + gamma)^2  + 
#                 (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + db_f4_ACC_ins + gamma)^2  + 
#                  v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(w4vhd)
# anova(w1,w2h,w3hd,w4vhd)
# # these other regions explain a lot of variance, but the multi-collinearity is tough
# 
# # RTs
# wr1 <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + gamma)^2 + v_max_b + v_entropy_b + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(wr1)
# wr2h <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + hb_f1_DAN_vlPFC + gamma)^3 
#              +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + hb_f2_neg_paralimb + gamma)^3 
#              + v_max_b + v_entropy_b +  (1|id/run), dfc)
# screen.lmerTest(wr2h)
# # reduced
# wr2h <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + hb_f1_DAN_vlPFC + gamma)^3 
#              +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag +  hb_f2_neg_paralimb + gamma)^3 
#              + v_max_b + v_entropy_b +  (1|id/run), dfc)
# 
# 
# wr3hd <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + hb_f1_DAN_vlPFC + gamma)^3 
#              +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + hb_f2_neg_paralimb + gamma)^3 
#              +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + db_f1_rIFG_rSMA + gamma)^3 
#              +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + db_f4_ACC_ins + gamma)^3 
#              + v_max_b + v_entropy_b +  (1|id/run), dfc)
# wr4hvd <- lmer(rt_csv ~ (scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + hb_f1_DAN_vlPFC + gamma)^3 
#               +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + hb_f2_neg_paralimb + gamma)^3 
#               +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + vb_f3_hi_blITG + gamma)^3 
#               +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + vb_f4_lo_cerebell_crus + gamma)^3 
#               +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + vb_f5_lo_ACC + gamma)^3 
#               +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + db_f1_rIFG_rSMA + gamma)^3 
#               +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + db_f2_VS + gamma)^3 
#               +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + db_f3_occ_parietal + gamma)^3 
#               +(scale(-1/run_trial) + scale(rt_lag) + scale(rt_vmax_lag) + omission_lag + v_max_wi_lag + v_entropy_wi + db_f4_ACC_ins + gamma)^3 
#               + v_max_b + v_entropy_b +  (1|id/run), dfc)
# 
# screen.lmerTest(wr4hvd)
# anova(wr1,wr2h,wr3hd,wr4hvd)
# 
# #####
# ## prediction of BS
# # lagged relationship between ACC and DAN
# b1 <- lmer(hb_f1_DAN_vlPFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + h1_lag + gamma)^2 
#               + v_max_b + v_entropy_b + scale(rt_csv) + rewFuncIEVsum + (1|id) + (1|run), df)
# screen.lmerTest(b1)
# # control for RT
# b1a <- lmer(hb_f1_DAN_vlPFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + h1_lag + gamma)^2 
#            + v_max_b + v_entropy_b + scale(rt_csv) +  (1|id) + (1|run), df)
# screen.lmerTest(b1a)
# b1b <- lmer(hb_f2_neg_paralimb ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + h1_lag + gamma)^2 
#             + v_max_b + v_entropy_b + scale(rt_csv) +  (1|id) + (1|run), df)
# screen.lmerTest(b1b)
# # how does RT scale with entropy?
# ggplot(df,aes(rt_csv, v_entropy)) + geom_smooth(method = 'gam')
# 
# # shockingly, it is present in high-gamma subjects
# b2 <- lmer(hb_f1_DAN_vlPFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma + h1_lag + d4_lag)^2 
#            + v_max_b + v_entropy_b + (1|run), df)
# screen.lmerTest(b2)
# # does this happen with any region?
# b3 <- lmer(hb_f1_DAN_vlPFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma + h1_lag + h2_lag)^2 
#            + v_max_b + v_entropy_b + (1|run), df)
# screen.lmerTest(b3)
# # it does for h2_paralimbic, but not for VS
# b4 <- lmer(hb_f1_DAN_vlPFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma + 
#                                 h1_lag + db_f1_rIFG_rSMA + d1_lag + db_f4_ACC_ins + d4_lag)^2 
#            + v_max_b + v_entropy_b + (1|run), df)
# screen.lmerTest(b4)
# b5 <- lmer(hb_f1_DAN_vlPFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma + h1_lag + d2_lag)^2 
#            + v_max_b + v_entropy_b + (1|run), df)
# screen.lmerTest(b5)
# # is it really a lagged relationship?
# # yes, although VIF = 2.73
# b5 <- lmer(hb_f1_DAN_vlPFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma + h1_lag + db_f4_ACC_ins + d4_lag)^2 
#            + v_max_b + v_entropy_b + (1|run), df)
# screen.lmerTest(b5)
# # seems to hold with h2, although VIFs are atrocious
# b6 <- lmer(hb_f1_DAN_vlPFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma + 
#                                 h1_lag + db_f4_ACC_ins + d4_lag + hb_f2_neg_paralimb + h2_lag)^2 
#            + v_max_b + v_entropy_b + (1|run), df)
# screen.lmerTest(b6)
# 
# # similar for V- ACC region
# b7 <- lmer(hb_f1_DAN_vlPFC ~ scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma + 
#                                 h1_lag + vb_f5_lo_ACC + v5_lag + hb_f2_neg_paralimb + h2_lag
#            + v_max_b + v_entropy_b + (1|run), df)
# screen.lmerTest(b7)
# 
# # a lot of interactions between regions...
# b8 <- lmer(hb_f1_DAN_vlPFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + gamma + 
#                                 h1_lag + vb_f5_lo_ACC + v5_lag + hb_f2_neg_paralimb + h2_lag)^3 
#            + v_max_b + v_entropy_b + (1|run), df)
# screen.lmerTest(b8)

# AH much more sensitive to entropy
summary(b9a <- lmer(h_ant_hipp_b_f ~ v_entropy_wi_lag + omission_lag + scale(rt_lag) + (1|run), df))
screen.lmerTest(b9a)

# PH slightly more sensitive to reward/omission and INsensitive to entropy
summary(b10a <- lmer(peb_f2_p_hipp ~ v_entropy_wi + omission_lag + scale(rt_csv) + (1|run), df))
screen.lmerTest(b10a)

# positive control: robust but mostly unsigned PE signals in f1/cortico-thalamo-striatal network
b10b <- lmer(peb_f1_cort_str ~ scale(-1/run_trial) + scale(rt_csv) + pe_max_lag +
             + (1|run), df)
screen.lmerTest(b10b)

b10b_lag2 <- lmer(peb_f1_cort_str ~ scale(-1/run_trial) + scale(rt_csv) + pe_max + pe_max_lag + pe_max_lag2 +
               + (1|run), df)
screen.lmerTest(b10b_lag2)

b10b_lag3 <- lmer(peb_f1_cort_str ~ scale(-1/run_trial) + scale(rt_csv) + pe_max + pe_max_lag + pe_max_lag2 + pe_max_lag3 + 
                    + (1|run), df)
screen.lmerTest(b10b_lag3)


b10b1 <- lmer(peb_f1_cort_str ~ scale(-1/run_trial) + scale(rt_csv) + abs(pe_max_lag) +
               + (1|run), df)
screen.lmerTest(b10b1)
b10b2 <- lmer(peb_f1_cort_str ~ scale(-1/run_trial) + scale(rt_csv) + omission_lag +
                + (1|run), df)
screen.lmerTest(b10b2)
# adding pe_max_lag to reward/omission improves AIC by 9 points
b10b3 <- lmer(peb_f1_cort_str ~ scale(-1/run_trial) + scale(rt_csv) + omission_lag + pe_max_lag +
                + (1|run), df)
screen.lmerTest(b10b3)

anova(b10b,b10b1,b10b2,b10b3)

# interestingly, even though the PE signal in PH is weaker than in the f1 network, it is signed rather than unsigned.
b10c <- lmer(peb_f2_p_hipp ~ scale(-1/run_trial) + scale(rt_lag) + pe_max_lag +
               + (1|id) + (1|run), dfc)
screen.lmerTest(b10c)
b10c1 <- lmer(peb_f2_p_hipp ~ scale(-1/run_trial) + scale(rt_lag) + abs(pe_max_lag) +
               + (1|id) + (1|run), dfc)
screen.lmerTest(b10c1)
# also, it responds to rewards vs. omissions, and PE does not explain additional variance
b10c2 <- lmer(peb_f2_p_hipp ~ scale(-1/run_trial) + scale(rt_lag) + omission_lag +
                + (1|run), dfc)
screen.lmerTest(b10c2)

b10c2a <- lmer(peb_f2_p_hipp ~ scale(-1/run_trial) + scale(rt_lag) + I(score_csv==0) +
                + (1|run), dfc)
screen.lmerTest(b10c2a)

# adding PE to reward/omission does not improve the model -- PH responds to valence more so than to PE
b10c3 <- lmer(peb_f2_p_hipp ~ scale(-1/run_trial) + scale(rt_lag) + omission_lag + pe_max_lag +
                + (1|run), dfc)
summary(b10c3)
screen.lmerTest(b10c2)
anova(b10c1,b10c,b10c2,b10c3)

# PH not sensitive to magnitude of positive outcomes
dfp <- df[!df$omission_lag,]
dfn <- df[df$omission_lag,]
b10c4 <- lmer(peb_f2_p_hipp ~ scale(-1/run_trial) + scale(rt_csv) + scale(magnitude) +
                + (1|id), dfp)
summary(b10c4)
# but peb1 is sensitive to magnitude...
b10c5 <- lmer(peb_f1_cort_str ~ scale(-1/run_trial) + scale(rt_csv) + scale(magnitude) +
                + (1|id), dfp)
summary(b10c5)
# PH relatively more sensitive to PE-
b10c6 <- lmer(peb_f2_p_hipp ~ scale(-1/run_trial) + scale(rt_csv) + scale(pe_max_lag) +
                + (1|id), dfn)
summary(b10c6)
# cortico-striatal peb1 is NOT sensitive to PE-
b10c7 <- lmer(peb_f1_cort_str ~ scale(-1/run_trial) + scale(rt_csv) + scale(pe_max_lag) +
                + (1|id), dfn)
summary(b10c7)

# is this the case for RT swing prediction?
# lagged beta series do not explain much
# s0 <- lmer(log(rt_swing) ~  (scale(-1/run_trial) + + omission_lag + v_max_wi_lag + v_entropy_wi + 
#                   h1_lag + h2_lag + d1_lag + d4_lag + gamma)^2 
#               + v_max_b + v_entropy_b + scale(rt_swing_lag) + scale(rt_lag) + (1|id/run), dfc)
# screen.lmerTest(s0)
# 

#####
## value or entropy in DAN?
## ENTROPY even in V-negative region!
v1 <- lmer(vb_f1_lo_DAN ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + v1_lag + gamma)^2 
           + v_max_b + v_entropy_b +  (1|id) + (1|run), dfc)
screen.lmerTest(v1)
v2 <- lmer(vb_f2_hi_vmPFC_cOFC ~ (scale(-1/run_trial) + omission_lag + v_max_wi + v_entropy_wi + v2_lag + gamma)^2 
           + v_max_b + v_entropy_b +  (1|id) + (1|run), dfc)
screen.lmerTest(v2)


