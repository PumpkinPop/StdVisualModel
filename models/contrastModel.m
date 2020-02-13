classdef contrastModel
    
    % The basic properties of the class
    properties 
        fittime        
        num_param         = 2
        param_name        = ['g'; 'n']
        param             = []
        param_bound       = [ 0, 100; 0,   1  ]
        param_pbound      = [ 1,  10;  .1, .5 ]
        model_type        = 'orientation'
        legend            = 'contrast'
    end
    
    methods
        
        % init the model
        function model = contrastModel( param_bound, param_pbound, fittime )
            if (nargin < 3), fittime = 5; end
            if (nargin < 2), param_pbound = [ 1,  10;  .1, .5 ]; end
            if (nargin < 1), param_bound  = [ 0, 100; 0,   1  ]; end
            
            if size(param_bound,1) ~= model.num_param
                disp('Wrong Bound')
            elseif size(param_pbound, 1) ~= model.num_param
                disp('Wrong Possible Bound')
            end
            
            model.param_bound  = param_bound;
            model.param_pbound = param_pbound; 
            model.fittime      = fittime;
        end
           
    end
        
        
    
    methods ( Static = true )
        
        % fix parameters
        function model = fixparameters( model, param )
            model.param = param;
            model.legend = sprintf('contrast %s=%.2f %s=%.2f',...
                            model.param_name(1), param(1),... 
                            model.param_name(2), param(2) );
        end
        
        % the core model function 
        function y_hat = forward( x, param )
            
            % set param
            g = param(1);
            n = param(2);
            
            % d: ori x exp x stim
            d = x;
            
            % sum over orientation, s: exp x stim 
            s = squeeze(mean(d, 1));
            
            % add gain and nonlinearity, yi_hat: exp x stim
            yi_hat = g .* s .^ n; 

            % Sum over different examples, y_hat: stim 
            y_hat = squeeze(mean(yi_hat, 1));
   
        end
            
        % predict the BOLD response: y_hat = f(x)
        function BOLD_pred = predict( model, E_ori )
            
            BOLD_pred = model.forward( E_ori, model.param );
            
        end
        
        % measure the goodness of 
        function Rsquare = metric( BOLD_pred, BOLD_target )
            
            Rsquare = 1 - var( BOLD_target - BOLD_pred ) / var( BOLD_target );
            
        end
        
        % loss function with sum sqaure error: sum( y - y_hat ).^2
        function sse = loss_fn(param, model, E_ori, y_target )
            
            % predict y_hat: 1 x stim 
            y_hat = model.forward( E_ori, param );
            
            % square error
            square_error = (y_target - y_hat).^2;
            
            % sse
            sse = double(mean(square_error));
        end
        
        % fit the data 
        function [loss, param] = optim( model, E_ori, BOLD_target, verbose )
            
            % set up the loss function
            func=@(x) model.loss_fn( x, model, E_ori, BOLD_target );
            
            opts.Display = verbose;
            
            % set up the bound
            lb  = model.param_bound( :, 1 );
            ub  = model.param_bound( :, 2 );
            plb = model.param_pbound( :, 1 );
            pub = model.param_pbound( :, 2 );
            
            % init param
            x0_set = ( lb + ( ub - lb ) .* rand( model.num_param, model.fittime ) )';
            
            % storage
            x   = NaN( model.fittime, model.num_param );
            sse = NaN( model.fittime, 1 );
            
            % fit with n init
            for ii = 1:model.fittime
                
                % optimization
                [ x(ii, :), sse(ii) ] = bads( func, x0_set(ii, :), lb', ub', plb', pub', [], opts);
                
            end
            
            % find the lowest sse
            loss  = min(sse);
            trial = find( sse == loss );
            param = x( trial(1), : ); 
            
        end
        
        % fit the data
        function [losses, params, Rsquare, model] = fit( model, E_ori, BOLD_target, verbose, cross_valid )
            
             if (nargin < 5), cross_valid = 'one'; end
            
            switch cross_valid
                
                case 'one'
                    
                    [loss, param] = model.optim( model, E_ori, BOLD_target, verbose );
                    params = param;
                    losses = loss;
                    Rsquare = [];
                    model  = model.fixparameters( model, param );
                    
                case 'cross_valid'
            
                    % achieve stim vector
                    stim_vector = 1 : size( E_ori, 3 );

                    % storage
                    BOLD_pred = nan( size( E_ori, 3 ) );
                    params    = nan( model.num_param, size( E_ori, 3 ) );
                    losses    = nan( size( E_ori, 3 ) );

                    % cross_valid  
                    for knock_idx = stim_vector

                        % train vector and train data
                        keep_idx = setdiff( stim_vector, knock_idx );
                        E_train  = E_ori( :, :, keep_idx );
                        size(E_train)
                        target_train = BOLD_target( keep_idx );
                        E_test   = E_ori( :, :, knock_idx );
                        size(E_test)
                        

                        % fit the training data 
                        [loss, param] = model.optim( model, E_train, target_train, verbose );
                        params( :, knock_idx ) = param;
                        losses( knock_idx ) = loss;
                        
                        % predict test data 
                        BOLD_pred( knock_idx ) = model.forward( E_test, param );
                        
                    end 
                    
                    % evaluate performance of the algorithm on test data
                    Rsquare = 1 - sum((BOLD_target - BOLD_pred).^2) / sum((BOLD_target - mean(BOLD_target)).^2);
                    
                    % bootstrap to get the param
                    params_boot = mean( params, 1 );
                    model  = model.fixparameters( model, params_boot );
            end
                      
        end
        
    end
end