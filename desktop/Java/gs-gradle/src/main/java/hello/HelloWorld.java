package hello;

import org.joda.time.LocalDate;

public class HelloWorld {
  public static void main(String[] args) {
	LocalDate currentDate = new LocalDate();
	System.out.println("The current year is: " + currentDate.getYear());

	Greeter greeter = new Greeter();
	System.out.println(greeter.sayHello());
  }
}
