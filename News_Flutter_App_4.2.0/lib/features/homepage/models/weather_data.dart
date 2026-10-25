class WeatherDetails {
  String? name;
  String? region;
  double? tempC;
  String? text;
  String? icon;
  double? minTempC;
  double? maxTempC;
  String? country;

  WeatherDetails({this.name, this.region, this.tempC, this.text, this.icon, this.maxTempC, this.minTempC, this.country});

  factory WeatherDetails.fromJson(Map<String, dynamic> json) {
    return WeatherDetails(
        name: json["location"]["name"],
        region: json["location"]["region"],
        country: json["location"]["country"],
        tempC: json["current"]["temp_c"],
        text: json["current"]["condition"]["text"],
        icon: json["current"]["condition"]["icon"],
        maxTempC: json["forecast"]["forecastday"][0]["day"]["maxtemp_c"],
        minTempC: json["forecast"]["forecastday"][0]["day"]["mintemp_c"]);
  }
}
