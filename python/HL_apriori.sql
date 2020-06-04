/* Generación de consulta para generar información que alimentará el Método Apriori en Python
   el cual tendrá el Ticket y una cadena de artículos comprados en ese Ticket  */

-- Creamos la tabla temporal que albergará los tickets del día

DECLARE @FINI varchar(10), @FFIN varchar(10)

SET @FINI='20200101' 
SET @FFIN='20200601'

DECLARE @TICKETS as Table (Ticket varchar(250),Almacen varchar(10),Fecha datetime , Familias varchar(max), [Fam-Marca] varchar(max), Marcas varchar(max))

insert into @TICKETS (Ticket, Almacen,Fecha)
select distinct [Nº Documento],[Cód. Almacén],[Fecha Registro] from ventas 
where [Fecha Registro]>=@FINI and [Fecha Registro]<=@FFIN and Cantidad>0


/* En este paso llenaremos el detalle mediante dos cursores */

DECLARE @Documento varchar(250), @Detalle varchar(max), @Familia varchar(250), @Fam_Mar varchar(max), @Marca varchar(max)

set @Detalle=''
set @Documento=''
set @Familia=''
set @Fam_Mar=''
set @Marca=''

DECLARE CursorTickets CURSOR FOR
Select Ticket from @TICKETS;

OPEN CursorTickets
    FETCH NEXT FROM CursorTickets into @Documento

	WHILE @@FETCH_STATUS = 0 BEGIN   -- Recorremos los tickets y consultamos los detalles en la tabla de ventas mediante otro cursor 
	    print @Documento
		DECLARE CursorVentas CURSOR FOR 
		
		Select distinct Familia from Ventas where [Nº Documento]=@Documento and [Fecha Registro]>=@FINI and [Fecha Registro]<=@FFIN and 
		                                   Familia not in('ETIQADH','SACO DAMA','PANTALONVD','ABRIGO D','CINTBORD','EMPAQUE','PORTATRAJE','MEDALLON','CUBREPOLVO','BOLSA','CAJA','ETIQBORD','PORTACORBA','ACCESORIOS','BOTONES','PROTECTOR',''
                   ,'BERMUDA D','BLAZER D','BLUSA','BOLSA','BOLSA D','BORDADO','CAJA','CAJA REG','CALZADO D','CAMISA','CHAMARRAD','CINTBORD','CINTUROND','CORBATAKIT',
                'CUBREPOLVO','EMPAQUE','ETIQADH','FAJA&MOÑO','FRACK','GUANTES','JEANS D','JOYERIA','LOC Y PERF','MAQUINOFF','MOÑO','PANTALON SD','PANTALON VD',
                'PANTALONSD','PANTS DAMA','PARAGUAS','PLAYERA D','PORTACORBA','PORTATRAJE','PROTECTOR','ROPA','ROPA INT.','ROPA INTD','SACO SP','SOMBRERO','SUETER D',
                'TRAJE BAÑO','VESTIDO','')

		Open CursorVentas
			FETCH NEXT FROM CursorVentas into @Familia

			WHILE @@FETCH_STATUS = 0 BEGIN
				set @Detalle=@Detalle+@Familia+','
				print @Familia
				FETCH NEXT FROM CursorVentas into @Familia
			END -- Fin del ciclo Cursor Ventas

		Close CursorVentas
		DEALLOCATE CursorVentas -- Liberamos memoria del CursorVenta
		-- Con los datos obtenidos actualizamos la tabla temporal
		SET @Detalle=LEFT(@Detalle,LEN(@Detalle)-1)
		update @TICKETS set Familias=@Detalle where Ticket=@Documento
		set @Detalle=''

/******************  Cursor para obtener las Marcas *************************************/
		DECLARE CursorMarcas CURSOR FOR 
		
		Select distinct Colección from Ventas where [Nº Documento]=@Documento and [Fecha Registro]>=@FINI and [Fecha Registro]<=@FFIN and 
		                                   Familia not in('ETIQADH','SACO DAMA','PANTALONVD','ABRIGO D','CINTBORD','EMPAQUE','PORTATRAJE','MEDALLON','CUBREPOLVO','BOLSA','CAJA','ETIQBORD','PORTACORBA','ACCESORIOS','BOTONES','PROTECTOR',''
                   ,'BERMUDA D','BLAZER D','BLUSA','BOLSA','BOLSA D','BORDADO','CAJA','CAJA REG','CALZADO D','CAMISA','CHAMARRAD','CINTBORD','CINTUROND','CORBATAKIT',
                'CUBREPOLVO','EMPAQUE','ETIQADH','FAJA&MOÑO','FRACK','GUANTES','JEANS D','JOYERIA','LOC Y PERF','MAQUINOFF','MOÑO','PANTALON SD','PANTALON VD',
                'PANTALONSD','PANTS DAMA','PARAGUAS','PLAYERA D','PORTACORBA','PORTATRAJE','PROTECTOR','ROPA','ROPA INT.','ROPA INTD','SACO SP','SOMBRERO','SUETER D',
                'TRAJE BAÑO','VESTIDO','')

		Open CursorMarcas
			FETCH NEXT FROM CursorMarcas into @Marca

			WHILE @@FETCH_STATUS = 0 BEGIN
				set @Detalle=@Detalle+@Marca+','
				print @Marca
				FETCH NEXT FROM CursorMarcas into @Marca
			END -- Fin del ciclo Cursor Ventas

		Close CursorMarcas
		DEALLOCATE CursorMarcas -- Liberamos memoria del CursorMarcas
		-- Con los datos obtenidos actualizamos la tabla temporal
		SET @Detalle=LEFT(@Detalle,LEN(@Detalle)-1)
		update @TICKETS set Marcas=@Detalle where Ticket=@Documento
		set @Detalle=''
         
		
/***********************  Fin Cursor Marcas **********************************************/


/******************  Cursor para obtener las Familia-Marcas *************************************/
		DECLARE CursorFamMar CURSOR FOR 
		
		Select distinct Familia,Colección from Ventas where [Nº Documento]=@Documento and [Fecha Registro]>=@FINI and [Fecha Registro]<=@FFIN and 
		                                   Familia not in('ETIQADH','SACO DAMA','PANTALONVD','ABRIGO D','CINTBORD','EMPAQUE','PORTATRAJE','MEDALLON','CUBREPOLVO','BOLSA','CAJA','ETIQBORD','PORTACORBA','ACCESORIOS','BOTONES','PROTECTOR',''
                   ,'BERMUDA D','BLAZER D','BLUSA','BOLSA','BOLSA D','BORDADO','CAJA','CAJA REG','CALZADO D','CAMISA','CHAMARRAD','CINTBORD','CINTUROND','CORBATAKIT',
                'CUBREPOLVO','EMPAQUE','ETIQADH','FAJA&MOÑO','FRACK','GUANTES','JEANS D','JOYERIA','LOC Y PERF','MAQUINOFF','MOÑO','PANTALON SD','PANTALON VD',
                'PANTALONSD','PANTS DAMA','PARAGUAS','PLAYERA D','PORTACORBA','PORTATRAJE','PROTECTOR','ROPA','ROPA INT.','ROPA INTD','SACO SP','SOMBRERO','SUETER D',
                'TRAJE BAÑO','VESTIDO','')

		Open CursorFamMar
			FETCH NEXT FROM CursorFamMar into @Familia,@Marca

			WHILE @@FETCH_STATUS = 0 BEGIN
				set @Detalle=@Detalle+@Familia+'-'+@Marca+','
				print @Familia+'-'+@Marca
				FETCH NEXT FROM CursorFamMar into @Familia,@Marca
			END -- Fin del ciclo Cursor Ventas

		Close CursorFamMar
		DEALLOCATE CursorFamMar -- Liberamos memoria del CursorMarcas
		-- Con los datos obtenidos actualizamos la tabla temporal
		SET @Detalle=LEFT(@Detalle,LEN(@Detalle)-1)
		update @TICKETS set [Fam-Marca]=@Detalle where Ticket=@Documento
		set @Detalle=''
         
		
/***********************  Fin Cursor Familia-Marcas **********************************************/



			FETCH NEXT FROM CursorTickets into @Documento
			
		END
		
	CLOSE CursorTickets
	DEALLOCATE CursorTickets

SELECT * from @TICKETS