/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0x7708f090 */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "C:/SoundboxProject/Source/soundbox-vhdl/ISEProject/Soundbox/Source/Utilities/ClockDivider.vhd";
extern char *IEEE_P_2592010699;

unsigned char ieee_p_2592010699_sub_1744673427_503743352(char *, char *, unsigned int , unsigned int );


static void work_a_3169215649_1446275585_p_0(char *t0)
{
    char *t1;
    char *t2;
    unsigned int t3;
    unsigned char t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;

LAB0:    xsi_set_current_line(25, ng0);

LAB3:    t1 = (t0 + 1512U);
    t2 = *((char **)t1);
    t3 = (0 + 4U);
    t1 = (t2 + t3);
    t4 = *((unsigned char *)t1);
    t5 = (t0 + 4000);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    t8 = (t7 + 56U);
    t9 = *((char **)t8);
    *((unsigned char *)t9) = t4;
    xsi_driver_first_trans_fast_port(t5);

LAB2:    t10 = (t0 + 3888);
    *((int *)t10) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void work_a_3169215649_1446275585_p_1(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    unsigned char t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;

LAB0:    xsi_set_current_line(29, ng0);
    t1 = (t0 + 1032U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB2;

LAB4:    t1 = (t0 + 1152U);
    t3 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t3 != 0)
        goto LAB5;

LAB6:
LAB3:    t1 = (t0 + 3904);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(30, ng0);
    t1 = (t0 + 4064);
    t5 = (t1 + 56U);
    t6 = *((char **)t5);
    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    *((int *)t8) = 0;
    xsi_driver_first_trans_delta(t1, 0U, 1, 0LL);
    xsi_set_current_line(31, ng0);
    t1 = (t0 + 4064);
    t2 = (t1 + 56U);
    t5 = *((char **)t2);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)2;
    xsi_driver_first_trans_delta(t1, 1U, 1, 0LL);
    goto LAB3;

LAB5:    xsi_set_current_line(33, ng0);
    t2 = (t0 + 1672U);
    t5 = *((char **)t2);
    t2 = (t0 + 4064);
    t6 = (t2 + 56U);
    t7 = *((char **)t6);
    t8 = (t7 + 56U);
    t9 = *((char **)t8);
    memcpy(t9, t5, 8U);
    xsi_driver_first_trans_fast(t2);
    goto LAB3;

}

static void work_a_3169215649_1446275585_p_2(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    unsigned int t4;
    int t5;
    unsigned char t6;
    char *t7;
    unsigned int t8;
    int t9;
    char *t10;
    char *t11;

LAB0:    xsi_set_current_line(40, ng0);
    t1 = (t0 + 1512U);
    t2 = *((char **)t1);
    t1 = (t0 + 2088U);
    t3 = *((char **)t1);
    t1 = (t3 + 0);
    memcpy(t1, t2, 8U);
    xsi_set_current_line(42, ng0);
    t1 = (t0 + 1512U);
    t2 = *((char **)t1);
    t4 = (0 + 0U);
    t1 = (t2 + t4);
    t5 = *((int *)t1);
    t6 = (t5 == 0);
    if (t6 != 0)
        goto LAB2;

LAB4:    xsi_set_current_line(45, ng0);
    t1 = (t0 + 2088U);
    t2 = *((char **)t1);
    t4 = (0 + 4U);
    t1 = (t2 + t4);
    *((unsigned char *)t1) = (unsigned char)2;

LAB3:    xsi_set_current_line(48, ng0);
    t1 = (t0 + 2088U);
    t2 = *((char **)t1);
    t4 = (0 + 0U);
    t1 = (t2 + t4);
    t5 = *((int *)t1);
    t9 = (4 - 1);
    t6 = (t5 == t9);
    if (t6 != 0)
        goto LAB5;

LAB7:    xsi_set_current_line(51, ng0);
    t1 = (t0 + 1512U);
    t2 = *((char **)t1);
    t4 = (0 + 0U);
    t1 = (t2 + t4);
    t5 = *((int *)t1);
    t9 = (t5 + 1);
    t3 = (t0 + 2088U);
    t7 = *((char **)t3);
    t8 = (0 + 0U);
    t3 = (t7 + t8);
    *((int *)t3) = t9;

LAB6:    xsi_set_current_line(54, ng0);
    t1 = (t0 + 2088U);
    t2 = *((char **)t1);
    t1 = (t0 + 4128);
    t3 = (t1 + 56U);
    t7 = *((char **)t3);
    t10 = (t7 + 56U);
    t11 = *((char **)t10);
    memcpy(t11, t2, 8U);
    xsi_driver_first_trans_fast(t1);
    t1 = (t0 + 3920);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(43, ng0);
    t3 = (t0 + 2088U);
    t7 = *((char **)t3);
    t8 = (0 + 4U);
    t3 = (t7 + t8);
    *((unsigned char *)t3) = (unsigned char)3;
    goto LAB3;

LAB5:    xsi_set_current_line(49, ng0);
    t3 = (t0 + 2088U);
    t7 = *((char **)t3);
    t8 = (0 + 0U);
    t3 = (t7 + t8);
    *((int *)t3) = 0;
    goto LAB6;

}


extern void work_a_3169215649_1446275585_init()
{
	static char *pe[] = {(void *)work_a_3169215649_1446275585_p_0,(void *)work_a_3169215649_1446275585_p_1,(void *)work_a_3169215649_1446275585_p_2};
	xsi_register_didat("work_a_3169215649_1446275585", "isim/ClockDivider_tb_isim_beh.exe.sim/work/a_3169215649_1446275585.didat");
	xsi_register_executes(pe);
}
