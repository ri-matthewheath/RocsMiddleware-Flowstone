## EMUpdater

EMUpdater reads customer information from PostgreSQL x3.customer table in [[X3ROCS]] and updates [[Exportmaster]] using its DLL interface. XML generation is performed by a PostgreSQL stored procedures (`x3.generate_customer_xml` and `x3.generate_discount_xml`).

It runs on a [[Scheduled-Task]] on [[RIVSIS02]]

