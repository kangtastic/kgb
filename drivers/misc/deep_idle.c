/* drivers/misc/deep_idle.c
 *
 * Copyright 2011  Ezekeel
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/init.h>
#include <linux/device.h>
#include <linux/miscdevice.h>
#include <linux/deep_idle.h>

#define DEEPIDLE_VERSION 2

#define NUM_IDLESTATES 3

static bool deepidle_enabled = false;

static unsigned long num_idlecalls[NUM_IDLESTATES], time_in_idlestate[NUM_IDLESTATES]; 

static ssize_t deepidle_status_read(struct device * dev, struct device_attribute * attr, char * buf)
{
    return sprintf(buf, "%u\n", (deepidle_enabled ? 1 : 0));
}

static ssize_t deepidle_status_write(struct device * dev, struct device_attribute * attr, const char * buf, size_t size)
{
    unsigned int data;

    if(sscanf(buf, "%u\n", &data) == 1) 
	{
	    if (data == 1)
		{
		    pr_info("%s: DEEPIDLE enabled\n", __FUNCTION__);

		    deepidle_enabled = true;
		} 
	    else if (data == 0)
		{
		    pr_info("%s: DEEPIDLE disabled\n", __FUNCTION__);

		    deepidle_enabled = false;
		}
	    else 
		{
		    pr_info("%s: invalid input range %u\n", __FUNCTION__, data);
		}
	} 
    else 
	{
	    pr_info("%s: invalid input\n", __FUNCTION__);
	}

    return size;
}

static ssize_t show_idle_stats(struct device * dev, struct device_attribute * attr, char * buf)
{
    return sprintf(buf, "idle state             total (average)\n===================================================\nIDLE                   %lums (%lums)\nDEEP IDLE (TOP=ON)     %lums (%lums)\nDEEP IDLE (TOP=OFF)    %lums (%lums)\n",
		   time_in_idlestate[0], num_idlecalls[0] == 0 ? 0 : time_in_idlestate[0] / num_idlecalls[0],
		   time_in_idlestate[1], num_idlecalls[1] == 0 ? 0 : time_in_idlestate[1] / num_idlecalls[1],
		   time_in_idlestate[2], num_idlecalls[2] == 0 ? 0 : time_in_idlestate[2] / num_idlecalls[2]);
}

static ssize_t reset_idle_stats(struct device * dev, struct device_attribute * attr, const char * buf, size_t size)
{
    unsigned int data;

    if(sscanf(buf, "%u\n", &data) == 1) 
	{
	    if (data == 1)
		{
		    int i;

		    for (i = 0; i < NUM_IDLESTATES; i++)
			{
			    num_idlecalls[i] = 0;
			    time_in_idlestate[i] = 0;
			}
		}
	    else 
		{
		    pr_info("%s: invalid input range %u\n", __FUNCTION__, data);
		}
	} 
    else 
	{
	    pr_info("%s: invalid input\n", __FUNCTION__);
	}

    return size;
}

static ssize_t deepidle_version(struct device * dev, struct device_attribute * attr, char * buf)
{
    return sprintf(buf, "%u\n", DEEPIDLE_VERSION);
}

static DEVICE_ATTR(enabled, S_IRUGO | S_IWUGO, deepidle_status_read, deepidle_status_write);
static DEVICE_ATTR(idle_stats, S_IRUGO , show_idle_stats, NULL);
static DEVICE_ATTR(reset_stats, S_IWUGO , NULL, reset_idle_stats);
static DEVICE_ATTR(version, S_IRUGO , deepidle_version, NULL);

static struct attribute *deepidle_attributes[] = 
    {
	&dev_attr_enabled.attr,
	&dev_attr_idle_stats.attr,
	&dev_attr_reset_stats.attr,
	&dev_attr_version.attr,
	NULL
    };

static struct attribute_group deepidle_group = 
    {
	.attrs  = deepidle_attributes,
    };

static struct miscdevice deepidle_device = 
    {
	.minor = MISC_DYNAMIC_MINOR,
	.name = "deepidle",
    };

bool deepidle_is_enabled(void)
{
    return deepidle_enabled;
}
EXPORT_SYMBOL(deepidle_is_enabled);

void report_idle_time(int idle_state, int idle_time)
{
    num_idlecalls[idle_state]++;
    time_in_idlestate[idle_state] += (unsigned int)(idle_time + 500) / 1000;

    return;
}
EXPORT_SYMBOL(report_idle_time);

static int __init deepidle_init(void)
{
    int i, ret;

    pr_info("%s misc_register(%s)\n", __FUNCTION__, deepidle_device.name);

    ret = misc_register(&deepidle_device);

    if (ret) 
	{
	    pr_err("%s misc_register(%s) fail\n", __FUNCTION__, deepidle_device.name);

	    return 1;
	}

    if (sysfs_create_group(&deepidle_device.this_device->kobj, &deepidle_group) < 0) 
	{
	    pr_err("%s sysfs_create_group fail\n", __FUNCTION__);
	    pr_err("Failed to create sysfs group for device (%s)!\n", deepidle_device.name);
	}

    for (i = 0; i < NUM_IDLESTATES; i++)
	{
	    num_idlecalls[i] = 0;
	    time_in_idlestate[i] = 0;
	}

    return 0;
}

device_initcall(deepidle_init);

