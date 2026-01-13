/******************************************************************************
 *
 * Description:
 *   - Collection of UDF for gas-surface interaction
 *   - NASA7 polynomial to compute species enthalpies are included
 *
 * Supported Species:
 *   C2H4, O2, O, H2O, OH, CO2, CO, H2, H
 *
 * User has to:
 *   - Set *_WALL_ID values in order to identify cells adjacent to walls for GSI
 *******************************************************************************/

#include "udf.h"

/* ====== USER INPUT ====== */
#define HDPE_WALL_ID 10
#define PARAFFIN_WALL_ID 9
#define UDM_MDOT 0  // User Defined Memory for fuel specific mass flow rate
#define UDM_QWAL 1  // User Defined Memory for heat flux
#define UDM_REG 2   // User Defined Memory for regression rate
#define UDM_VEL 3   // User Defined Memory for fuel adduction velocity

/* ====== GRAIN PARAMETERS ====== */
#define ETILENE_DELTAH 4.6902e6 // Considering Paraffin at 340K and Etylene at 750K
#define PARAFFIN_RHO 870.0
#define PARAFFIN_RDOT 2e-3 // Define the fixed mass adduction

/* ====== MIXTURE CONSTANTS ====== */
#define R_UNIV 8.314462618 // J/(mol K)
#define TEMP_SPLIT 1000.0
#define LOW_TEMP  0
#define HIGH_TEMP 1
#define N_COEFFS 6
#define N_RANGES 2
#define NSPECIES 8
#define C2H4_ID 0
#define O2_ID 1
#define O_ID 2
#define H2O_ID 3
#define OH_ID 4
#define CO2_ID 5
#define CO_ID 6
#define H2_ID 7
#define H_ID 8



/* ====== NASA 7 Coefficients (a1–a6) for each species and temperature range ====== */
/* --------------------------------------------------------------------------------
         nasa_coeffs[species_id][range][coeff_index]
         range = 0: LOW_TEMP (< 1000 K)
         range = 1: HIGH_TEMP (≥ 1000 K)
   -------------------------------------------------------------------------------- */
/* ================================================================================ */
const real NASA7[10][N_RANGES][N_COEFFS] = {
    {   // C2H4
        {-8.614880e-01,  2.796162e-02, -3.388677e-05,  2.785152e-08, -9.737879e-12,  5.573046e+03},
        { 3.528418e+00,  1.148519e-02, -4.418385e-06,  7.844600e-10, -5.266848e-14,  4.428288e+03}
    },
    {   // O2
        { 3.212936e+00,  1.127486e-03, -5.756150e-07,  1.313877e-09, -8.768554e-13, -1.005249e+03},
        { 3.697578e+00,  6.135197e-04, -1.258842e-07,  1.775281e-11, -1.136435e-15, -1.233930e+03}
    },
    {   // O
        { 2.946428e+00, -1.638167e-03,  2.421031e-06, -1.602843e-09,  3.890696e-13,  2.914764e+04},
        { 2.542059e+00, -2.755061e-05, -3.102803e-09,  4.551067e-12, -4.368051e-16,  2.923080e+04}
    },
    {   // H2O
        { 3.262451e+00,  1.511941e-03, -3.881755e-06,  5.581944e-09, -2.474951e-12, -1.431054e+04},
        { 3.025078e+00,  1.442689e-03, -5.630827e-07,  1.018581e-10, -6.910951e-15, -1.426835e+04}
    },
    {   // OH
        { 2.275724e+00,  9.922072e-03, -1.040911e-05,  6.866686e-09, -2.117280e-12, -4.837314e+04},
        { 4.453623e+00,  3.140168e-03, -1.278411e-06,  2.393996e-10, -1.669033e-14, -4.896696e+04}
    },
    {   // CO2
        { 3.637266e+00,  1.850910e-04, -1.676165e-06,  2.387202e-09, -8.431442e-13,  3.606781e+03},
        { 2.882730e+00,  1.013974e-03, -2.276877e-07,  2.174683e-11, -5.126305e-16,  3.886888e+03}
    },
    {   // CO
        { 3.386842e+00,  3.474982e-03, -6.354696e-06,  6.968581e-09, -2.506588e-12, -3.020811e+04},
        { 2.672145e+00,  3.056293e-03, -8.730260e-07,  1.200996e-10, -6.391618e-15, -2.989921e+04}
    },
    {   // H2
        { 3.298124e+00,  8.249441e-04, -8.143015e-07, -9.475434e-11,  4.134872e-13, -1.012521e+03},
        { 2.991423e+00,  7.000644e-04, -5.633828e-08, -9.231578e-12,  1.582752e-15, -8.350340e+02}
    },
    {   // H
        { 2.500000e+00,  0.000000e+00,  0.000000e+00,  0.000000e+00,  0.000000e+00,  2.547162e+04},
        { 2.500000e+00,  0.000000e+00,  0.000000e+00,  0.000000e+00,  0.000000e+00,  2.547162e+04}
    }
};

/* ===== Species Molar Mass (kg/mol) ===== */
const real mol_weights[10] = {
    0.028054180000000,  // C2H4
    0.031998800000000,  // O2
    0.015999400000000,  // O
    0.018015340000000,  // H2O
    0.017007370000000,  // OH
    0.044009950000000,  // CO2
    0.028010550000000,  // CO
    0.002015940000000,  // H2
    0.001007970000000,  // H
};

/*--------------------------------------------------------------------------
  Function: compute_enthalpy
  Compute mass specific enthalpy for species "species_id" at temperature "T"
  --------------------------------------------------------------------------*/
real compute_enthalpy(real T, int species_id)
{
    int range = (T < TEMP_SPLIT) ? LOW_TEMP : HIGH_TEMP;
    const real *a = NASA7[species_id][range];

    real h_mol = R_UNIV * T * (
        a[0] + a[1]*T/2 + a[2]*T*T/3 + a[3]*T*T*T/4 + a[4]*T*T*T*T/5 + a[5]/T
    );

    /* mass specific enthalpy [J/kg] */
    return h_mol / mol_weights[species_id];
}

/*------------------------------------------------------------
  Function: compute_mdot_source_iso
  Compute the volumetric mass source value with isothermal wall
  ------------------------------------------------------------*/
real compute_mdot_source_iso(real q_wall, real DELTAH, real Volume)
{
    return -q_wall / (DELTAH * Volume);
}

/*-----------------------------------------------------
  DEFINE_SOURCE: ETILENE_mass_source
  Compute the volumetric mass source term for each cell
  -----------------------------------------------------*/
DEFINE_SOURCE(ETILENE_mass_source, cell, cell_thread, dS, eqn)
{
    /* Variable Initialization */ 
    real source = 0.0;
    real q_wall = 0.0;
    real Area = 0.0;
    real Volume = C_VOLUME(cell, cell_thread);

    int n;
    face_t face;
    Thread *face_thread;

    /* Loop over faces of the cell considered to extract heat flux
       and compute mdot with the appropriate function              */
    c_face_loop(cell, cell_thread, n)
    {
        face = C_FACE(cell, cell_thread, n);
        face_thread = C_FACE_THREAD(cell, cell_thread, n);

        if (THREAD_ID(face_thread) == PARAFFIN_WALL_ID)
        {
            /* Boundary Area */
            real Avec[ND_ND];
            F_AREA(Avec, face, face_thread);
            Area = NV_MAG(Avec);
            
            /* Wall heat flux */
            q_wall = BOUNDARY_HEAT_FLUX(face, face_thread);
            break;
        }
    }
    
    /* Forced Mass term */
    source = PARAFFIN_RHO*PARAFFIN_RDOT/10*Area/Volume;

    /* Writing of User Defined Memories */ 
    if (Area > 0.0)
    {
        C_UDMI(cell, cell_thread, UDM_MDOT) = source * Volume / Area;
        C_UDMI(cell, cell_thread, UDM_QWAL) = q_wall / Area;
    }

    dS[eqn] = 0.0;
    return source;
}



/*--------------------------------------------------------------------------------
  DEFINE_SOURCE: ETILENE_momentum_source_y
  Compute the volumetric mometum source term for each cell in the y-axis direction
  This is used by the mometum conservation along y-axis direction equation
  --------------------------------------------------------------------------------*/
DEFINE_SOURCE(ETILENE_momentum_source_y, cell, cell_thread, dS, eqn)
{
    /* Variable Initialization */ 
    real source = 0.0;
    real q_wall = 0.0;
    real T_wall = 0.0;
    real Area = 0.0;
    real Volume = C_VOLUME(cell, cell_thread);
    real mdot = 0.0;
    real vel = 0.0;
    real ni = 0.0;
    real regression = 0.0;

    face_t face;
    Thread *face_thread;
    int n;

    /* Loop over faces of the cell considered to extract heat flux
       and compute mdot and the source term                        */
    c_face_loop(cell, cell_thread, n)
    {
        face = C_FACE(cell, cell_thread, n);
        face_thread = C_FACE_THREAD(cell, cell_thread, n);

        if (THREAD_ID(face_thread) == PARAFFIN_WALL_ID)
        {
            /* Normal vector to the Boundary Area */
            real Avec[ND_ND];
            F_AREA(Avec, face, face_thread);
            Area = NV_MAG(Avec);

            /* Wall heat flux */
            q_wall = BOUNDARY_HEAT_FLUX(face, face_thread);

            /* Wall Temperature */
            T_wall = F_T(face, face_thread);

            /* Mass flow rate */
            mdot = PARAFFIN_RHO*PARAFFIN_RDOT/10*Area/Volume;
            
            /* Density of Etylene at wall */
            real rho = C_P(cell, cell_thread) * mol_weights[C2H4_ID] / R_UNIV / T_wall;

            /* Regression Rate */
            regression = mdot*Volume/(Area*PARAFFIN_RHO);

            /* Fuel Adduction velocity (scalar) */
            vel = mdot * Volume / (Area * rho);

            /* Normal vector along the y direction */
            ni = Avec[1] / Area;

            /* Forced Momentum source term */
            source = -mdot * vel * ni ;

            break;
        }
    }

    /* Writing of User Defined Memories */ 
    if (Area > 0.0)
    {
        C_UDMI(cell, cell_thread, UDM_REG) = regression;
        C_UDMI(cell, cell_thread, UDM_VEL) = vel;
    }

    dS[eqn] = 0.0;
    return source;
}

/*--------------------------------------------------------------------------------
  DEFINE_SOURCE: ETILENE_momentum_source_z
  Compute the volumetric mometum source term for each cell in the z-axis direction
  This is used by the mometum conservation along z-axis direction equation
  --------------------------------------------------------------------------------*/
DEFINE_SOURCE(ETILENE_momentum_source_z, cell, cell_thread, dS, eqn)
{
    /* Variable Initialization */ 
    real source = 0.0;
    real q_wall = 0.0;
    real T_wall = 0.0;
    real Area = 0.0;
    real Volume = C_VOLUME(cell, cell_thread);
    real mdot = 0.0;
    real vel = 0.0;
    real ni = 0.0;
    real regression = 0.0;

    face_t face;
    Thread *face_thread;
    int n;

    /* Loop over faces of the cell considered to extract heat flux
       and compute mdot and the source term                        */
    c_face_loop(cell, cell_thread, n)
    {
        face = C_FACE(cell, cell_thread, n);
        face_thread = C_FACE_THREAD(cell, cell_thread, n);

        if (THREAD_ID(face_thread) == PARAFFIN_WALL_ID)
        {
            /* Normal vector to the Boundary Area */
            real Avec[ND_ND];
            F_AREA(Avec, face, face_thread);
            Area = NV_MAG(Avec);

            /* Wall heat flux */
            q_wall = BOUNDARY_HEAT_FLUX(face, face_thread);

            /* Wall Temperature */
            T_wall = F_T(face, face_thread);

            /* Mass flow rate */
            mdot = PARAFFIN_RHO*PARAFFIN_RDOT/10*Area/Volume;
            
            /* Density of Etylene at wall */
            real rho = C_P(cell, cell_thread) * mol_weights[C2H4_ID] / R_UNIV / T_wall;

            /* Regression Rate */
            regression = mdot*Volume/(Area*PARAFFIN_RHO);

            /* Fuel Adduction velocity (scalar) */
            vel = mdot * Volume / (Area * rho);

            /* Normal vector along the z direction */
            ni = Avec[2] / Area;

            /* Forced Momentum source term */
            source = -mdot * vel * ni ;

            break;
        }
    }

    dS[eqn] = 0.0;
    return source;
}



/*-------------------------------------------------------
  DEFINE_SOURCE: ETILENE_energy_source
  Compute the volumetric energy source term for each cell
  -------------------------------------------------------*/
DEFINE_SOURCE(ETILENE_energy_source, cell, cell_thread, dS, eqn)
{
    /* Variable Initialization */ 
    real source = 0.0;
    real mdot = 0.0;
    real Area = 0.0;
    real q_wall = 0.0;
    real T_wall = 0.0;
    real vel = 0.0;
    real Volume = C_VOLUME(cell, cell_thread);

    int n;
    face_t face;
    Thread *face_thread;

    /* Loop over faces of the cell considered to extract heat flux
       and compute mdot and the source term                        */
    c_face_loop(cell, cell_thread, n)
    {
        face = C_FACE(cell, cell_thread, n);
        face_thread = C_FACE_THREAD(cell, cell_thread, n);

        if (THREAD_ID(face_thread) == PARAFFIN_WALL_ID)
        {
            /* Boundary Area */
            real Avec[ND_ND];
            F_AREA(Avec, face, face_thread);
            Area = NV_MAG(Avec);

            /* Wall heat flux */
            q_wall = BOUNDARY_HEAT_FLUX(face, face_thread);

            /* Wall Temperature */
            T_wall = F_T(face, face_thread);

            /* Mass flow rate */
            mdot = PARAFFIN_RHO*PARAFFIN_RDOT/10*Area/Volume;
            
            /* Enthalpy of Etylene at Wall Temperature */
            real h = compute_enthalpy(T_wall, C2H4_ID);

            /* Density of Etylene at wall */
            real rho = C_P(cell, cell_thread) * mol_weights[C2H4_ID] / R_UNIV / T_wall;

            /* Fuel Adduction velocity (scalar) */
            vel = mdot * Volume / (Area * rho);

            /* Forced Energy source term */
            source = mdot * ( h + vel*vel/2 );

            break;
        }
    }

    dS[eqn] = 0.0;
    return source;
}

/*--------------------------------------------------
  Function: max_pressure_file
    Create the file "pmax_udf.txt" that contains 
    the maximum pressure of the computational domain
  --------------------------------------------------*/
DEFINE_ON_DEMAND(max_pressure_file)
{
    /* Variable Initialization */ 
    Thread *t;
    cell_t c;
    Domain *d;
    real p;
    real pmax = -1e20;

    /* Get the computational domain */
    d = Get_Domain(1);

    /* Loop on all cells in order to determine maximum pressure */
    thread_loop_c(t, d)
    {
        begin_c_loop(c,t)
        {
            if (C_P(c,t) > pmax)
                pmax = C_P(c,t);
        }
        end_c_loop(c,t)
    }

    /* Rounding the pressure found and reporting it in bar */
    real pmax_bar = pmax / 100000.0;
    pmax_bar = ((int)(pmax_bar * 10 + 0.5)) / 10.0;

    /* Writing "pmax_udf.txt" output file */    
    if (pmax_bar > 0.0)
    {
        FILE *fp = fopen("pmax_udf.txt", "w");
        if (fp)
        {
            fprintf(fp, "%g\n", pmax_bar);
            fclose(fp);
        }
    }
}
