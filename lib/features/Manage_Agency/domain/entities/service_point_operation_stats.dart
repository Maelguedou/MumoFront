class ServicePointOperationStats {
  final int retraits;
  final int depots;
  final int transferts;
  final double commission;
  final String? date;
  final String? timezone;

  const ServicePointOperationStats({
    this.retraits = 0,
    this.depots = 0,
    this.transferts = 0,
    this.commission = 0,
    this.date,
    this.timezone,
  });

  int get total => retraits + depots + transferts;
}
