package com.mkyong.core.utils;

import java.util.Date;
import java.util.Calendar;
import java.util.GregorianCalendar;

public class DateUtils {

	public static void main(String[] args) {

		System.out.println(getCurrentYear());

	}

	private static int getCurrentYear() {

        Calendar calendar = new GregorianCalendar();
        calendar.setTime(new Date());
        int year = calendar.get(Calendar.YEAR);

		return year;

	}

}
