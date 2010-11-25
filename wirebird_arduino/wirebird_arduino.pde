void setup()
{
  Serial.begin(9600);
  Serial.println("Wirebird Start");
}

void loop()
{
  int raw = analogRead(0);
  int celsius0 = ( raw * 50000) / 1024;
  raw = analogRead(1);
  int celsius1 = ( raw * 50000) / 1024;
  raw = analogRead(2);
  int celsius2 = ( raw * 50000) / 1024;

  Serial.print("Celsius: ");
  Serial.print(celsius0);
  Serial.print(" ");
  Serial.print(celsius1);
  Serial.print(" ");
  Serial.println(celsius2);
 
  delay(200);
}
