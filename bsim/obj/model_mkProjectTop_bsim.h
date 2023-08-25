/*
 * Generated by Bluespec Compiler (build 7d25cde)
 * 
 * On Thu Aug 24 19:09:38 PDT 2023
 * 
 */

/* Generation options: */
#ifndef __model_mkProjectTop_bsim_h__
#define __model_mkProjectTop_bsim_h__

#include "bluesim_types.h"
#include "bs_module.h"
#include "bluesim_primitives.h"
#include "bs_vcd.h"

#include "bs_model.h"
#include "mkProjectTop_bsim.h"

/* Class declaration for a model of mkProjectTop_bsim */
class MODEL_mkProjectTop_bsim : public Model {
 
 /* Top-level module instance */
 private:
  MOD_mkProjectTop_bsim *mkProjectTop_bsim_instance;
 
 /* Handle to the simulation kernel */
 private:
  tSimStateHdl sim_hdl;
 
 /* Constructor */
 public:
  MODEL_mkProjectTop_bsim();
 
 /* Functions required by the kernel */
 public:
  void create_model(tSimStateHdl simHdl, bool master);
  void destroy_model();
  void reset_model(bool asserted);
  void get_version(unsigned int *year,
		   unsigned int *month,
		   char const **annotation,
		   char const **build);
  time_t get_creation_time();
  void * get_instance();
  void dump_state();
  void dump_VCD_defs();
  void dump_VCD(tVCDDumpType dt);
};

/* Function for creating a new model */
extern "C" {
  void * new_MODEL_mkProjectTop_bsim();
}

#endif /* ifndef __model_mkProjectTop_bsim_h__ */
